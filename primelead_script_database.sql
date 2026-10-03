-- PrimeLead Automation
-- MySQL 8.0
-- Evolucao do modelo para versionamento imutavel dos pesos e rastreabilidade do score.
--
-- IMPORTANTE:
-- 1. Este script pressupoe que as tabelas existentes se chamam:
--      empresa, possivel_cliente, match_empresa_lead,
--      preferencia_cliente, criterio_preferencia, origem_peso
--    e que match_empresa_lead possui id_match, fk_empresa,
--    fk_possivel_cliente e score.
-- 2. Revise os nomes/tipos das PKs e FKs no schema real antes de executar.
-- 3. Execute primeiro em ambiente de desenvolvimento e faca backup.
-- 4. O script nao apaga tabelas nem dados existentes.
--
-- Objetivos:
--   - Criar uma versao completa e imutavel da configuracao de score por empresa.
--   - Vincular pesos dos fatores e dos canais de origem a essa versao.
--   - Vincular cada score calculado a versao de pesos e versao da regressao.
--   - Impedir fatores/canais duplicados por versao.
--
-- A soma dos quatro fatores (fit, engajamento, comportamento, origem) deve ser 100.
-- MySQL CHECK nao consegue validar soma entre varias linhas; valide no procedimento
-- de publicacao (transacao) abaixo.

USE `PrimeLeadAutomation`;

-- ---------------------------------------------------------------------------
-- 1. Catalogo fixo de fatores
-- ---------------------------------------------------------------------------
-- Se preferencia_cliente ja tiver dados, preencha a coluna chave com os valores
-- canonicos antes de tornar a coluna NOT NULL/UNIQUE.
-- As chaves sao estaveis e devem ser usadas pelo codigo, nao o nome de exibicao.

ALTER TABLE `preferencia_cliente`
    ADD COLUMN `chave` VARCHAR(32) NULL;

-- Exemplo de preenchimento, ajuste os nomes conforme os dados reais:
UPDATE `preferencia_cliente`
SET `chave` = CASE LOWER(TRIM(`nome`))
    WHEN 'fit' THEN 'fit'
    WHEN 'engajamento' THEN 'engajamento'
    WHEN 'comportamento' THEN 'comportamento'
    WHEN 'origem' THEN 'origem'
    ELSE NULL
END
WHERE `chave` IS NULL;

-- IMPORTANTE: antes de prosseguir, confira se todas as linhas receberam chave.
-- SELECT id_preferencia_cliente, nome FROM preferencia_cliente WHERE chave IS NULL;
-- Para valores fora dos quatro fatores, defina a chave manualmente ou remova-os
-- apenas depois de confirmar que nao sao utilizados.

-- A restricao UNIQUE permite multiplos NULL no MySQL; por isso a coluna fica
-- NOT NULL somente apos o preenchimento dos dados existentes.
-- Execute este ALTER depois de corrigir todas as linhas com chave NULL:
-- ALTER TABLE `preferencia_cliente`
--     MODIFY COLUMN `chave` VARCHAR(32) NOT NULL,
--     ADD CONSTRAINT `uq_preferencia_cliente_chave` UNIQUE (`chave`);

-- ---------------------------------------------------------------------------
-- 2. Cabecalho de cada versao publicada da configuracao
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `versao_configuracao_score` (
    `id_versao_configuracao_score` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fk_empresa` BIGINT UNSIGNED NOT NULL,
    `numero_versao` INT UNSIGNED NOT NULL,
    `status_versao` ENUM('RASCUNHO', 'PUBLICADA') NOT NULL DEFAULT 'RASCUNHO',
    `criado_em` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `publicado_em` DATETIME(6) NULL,
    `criado_por` BIGINT UNSIGNED NULL,
    `observacao` VARCHAR(500) NULL,
    PRIMARY KEY (`id_versao_configuracao_score`),
    CONSTRAINT `uq_versao_score_empresa_numero`
        UNIQUE (`fk_empresa`, `numero_versao`),
    KEY `ix_versao_score_empresa_status` (`fk_empresa`, `status_versao`),
    CONSTRAINT `fk_versao_score_empresa`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE CASCADE ON DELETE RESTRICT
    -- Se usuario.id_usuario e do mesmo tipo, pode ativar:
    -- ,CONSTRAINT `fk_versao_score_usuario`
    --     FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`)
    --     ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- 3. Pesos dos fatores por versao
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `versao_score_fator` (
    `id_versao_score_fator` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fk_versao_configuracao_score` BIGINT UNSIGNED NOT NULL,
    `fk_preferencia_cliente` BIGINT UNSIGNED NOT NULL,
    `peso` DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (`id_versao_score_fator`),
    CONSTRAINT `uq_versao_score_fator`
        UNIQUE (`fk_versao_configuracao_score`, `fk_preferencia_cliente`),
    CONSTRAINT `ck_versao_score_fator_peso`
        CHECK (`peso` >= 0 AND `peso` <= 100),
    CONSTRAINT `fk_vsf_versao`
        FOREIGN KEY (`fk_versao_configuracao_score`)
        REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_vsf_preferencia`
        FOREIGN KEY (`fk_preferencia_cliente`)
        REFERENCES `preferencia_cliente` (`id_preferencia_cliente`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- 4. Pesos dos canais de origem por versao
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `versao_score_origem` (
    `id_versao_score_origem` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fk_versao_configuracao_score` BIGINT UNSIGNED NOT NULL,
    `canal` VARCHAR(64) NOT NULL,
    `peso` DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (`id_versao_score_origem`),
    CONSTRAINT `uq_versao_score_origem`
        UNIQUE (`fk_versao_configuracao_score`, `canal`),
    CONSTRAINT `ck_versao_score_origem_peso`
        CHECK (`peso` >= 0 AND `peso` <= 100),
    CONSTRAINT `fk_vso_versao`
        FOREIGN KEY (`fk_versao_configuracao_score`)
        REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- 5. Referenciar a versao usada em cada score
-- ---------------------------------------------------------------------------
ALTER TABLE `match_empresa_lead`
    ADD COLUMN `fk_versao_configuracao_score` BIGINT UNSIGNED NULL,
    ADD COLUMN `score_versao` VARCHAR(64) NULL,
    ADD COLUMN `calculado_em` DATETIME(6) NULL;

ALTER TABLE `match_empresa_lead`
    ADD CONSTRAINT `fk_match_versao_score`
    FOREIGN KEY (`fk_versao_configuracao_score`)
    REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
    ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE INDEX `ix_match_empresa_lead_versao`
    ON `match_empresa_lead` (`fk_empresa`, `fk_versao_configuracao_score`);

-- Depois de migrar/recalcular os scores antigos, avalie tornar as colunas NOT NULL.
-- Nao torne NOT NULL antes de preencher os registros existentes.

-- ---------------------------------------------------------------------------
-- 6. Publicar uma versao de configuracao
-- ---------------------------------------------------------------------------
-- O cliente deve salvar os pesos em uma nova versao RASCUNHO e chamar esta
-- procedure. Ela valida os quatro fatores e a soma 100, valida os canais,
-- e publica a versao. Scores devem usar apenas versoes PUBLICADAS.
--
-- Para preservar imutabilidade, a aplicacao nao deve atualizar/excluir pesos
-- de uma versao publicada. Para uma nova configuracao, crie outra versao.
-- Reforce essa regra com permissoes SQL ou triggers (ver observacoes ao final).

DELIMITER $$

CREATE PROCEDURE `publicar_configuracao_score`(
    IN p_id_versao BIGINT UNSIGNED
)
BEGIN
    DECLARE v_empresa BIGINT UNSIGNED;
    DECLARE v_status VARCHAR(20);
    DECLARE v_qtd_fatores INT DEFAULT 0;
    DECLARE v_soma DECIMAL(7,2) DEFAULT 0;
    DECLARE v_qtd_origens INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT `fk_empresa`, `status_versao`
      INTO v_empresa, v_status
      FROM `versao_configuracao_score`
     WHERE `id_versao_configuracao_score` = p_id_versao
     FOR UPDATE;

    IF v_status <> 'RASCUNHO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Somente versoes em RASCUNHO podem ser publicadas.';
    END IF;

    SELECT COUNT(*), COALESCE(SUM(vsf.`peso`), 0)
      INTO v_qtd_fatores, v_soma
      FROM `versao_score_fator` vsf
      JOIN `preferencia_cliente` pc
        ON pc.`id_preferencia_cliente` = vsf.`fk_preferencia_cliente`
     WHERE vsf.`fk_versao_configuracao_score` = p_id_versao
       AND pc.`chave` IN ('fit', 'engajamento', 'comportamento', 'origem');

    IF v_qtd_fatores <> 4 OR v_soma <> 100.00 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A configuracao deve conter os quatro fatores, somando exatamente 100.';
    END IF;

    -- Validacao de canais: deve haver pelo menos um canal cadastrado.
    -- Se o conjunto de canais for fixo, valide tambem a lista esperada aqui.
    SELECT COUNT(*)
      INTO v_qtd_origens
      FROM `versao_score_origem`
     WHERE `fk_versao_configuracao_score` = p_id_versao;

    IF v_qtd_origens = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cadastre pelo menos um canal de origem antes de publicar.';
    END IF;

    UPDATE `versao_configuracao_score`
       SET `status_versao` = 'PUBLICADA',
           `publicado_em` = CURRENT_TIMESTAMP(6)
     WHERE `id_versao_configuracao_score` = p_id_versao;

    COMMIT;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------------
-- 7. Impedir alteracao/exclusao de pesos apos publicacao
-- ---------------------------------------------------------------------------
-- Triggers de INSERT/UPDATE/DELETE verificam se a versao esta PUBLICADA.
-- Para simplificar a manutencao, este script inclui as tres operacoes nas
-- duas tabelas de pesos.

DELIMITER $$

CREATE TRIGGER `trg_vsf_no_insert_publicada`
BEFORE INSERT ON `versao_score_fator`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido inserir fatores em uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_vsf_no_update_publicada`
BEFORE UPDATE ON `versao_score_fator`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = OLD.`fk_versao_configuracao_score`) = 'PUBLICADA'
       OR (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido alterar fatores de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_vsf_no_delete_publicada`
BEFORE DELETE ON `versao_score_fator`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = OLD.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido excluir fatores de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_vso_no_insert_publicada`
BEFORE INSERT ON `versao_score_origem`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido inserir origens em uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_vso_no_update_publicada`
BEFORE UPDATE ON `versao_score_origem`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = OLD.`fk_versao_configuracao_score`) = 'PUBLICADA'
       OR (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido alterar origens de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_vso_no_delete_publicada`
BEFORE DELETE ON `versao_score_origem`
FOR EACH ROW
BEGIN
    IF (SELECT `status_versao`
          FROM `versao_configuracao_score`
         WHERE `id_versao_configuracao_score` = OLD.`fk_versao_configuracao_score`) = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido excluir origens de uma versao publicada.';
    END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------------
-- 8. Consulta de auditoria
-- ---------------------------------------------------------------------------
-- Mostra o score e a versao da configuracao usada. A coluna score_versao
-- representa a versao do modelo de regressao/parametros do cálculo.
SELECT
    mel.`id_match`,
    mel.`fk_empresa`,
    mel.`fk_possivel_cliente`,
    mel.`score`,
    mel.`fk_versao_configuracao_score`,
    vcs.`numero_versao` AS `versao_pesos`,
    mel.`score_versao` AS `versao_regressao`,
    mel.`calculado_em`
FROM `match_empresa_lead` mel
LEFT JOIN `versao_configuracao_score` vcs
  ON vcs.`id_versao_configuracao_score` = mel.`fk_versao_configuracao_score`;

-- ---------------------------------------------------------------------------
-- 9. Notas de integracao
-- ---------------------------------------------------------------------------
-- A) O backend deve criar uma nova versao RASCUNHO para cada salvamento.
-- B) Inserir os quatro fatores e os canais de origem nessa versao.
-- C) Chamar CALL publicar_configuracao_score(id_versao).
-- D) O worker de score deve ler apenas configuracoes PUBLICADAS da empresa.
-- E) Ao gravar match_empresa_lead, salvar fk_versao_configuracao_score,
--    score_versao e calculado_em junto com o score.
-- F) Para reproduzir o score integralmente, tambem preserve a versao dos dados
--    de entrada (ou um snapshot dos atributos usados no cálculo).
-- G) O script nao converte automaticamente os pesos existentes em criterio_preferencia
--    e origem_peso para as novas tabelas; essa migracao depende dos dados atuais.
-- H) Imutabilidade de versoes publicadas tambem deve ser protegida por permissoes
--    de banco: a conta da aplicacao nao deve ter UPDATE/DELETE livre nas tabelas
--    de configuracao, fora dos fluxos controlados.
