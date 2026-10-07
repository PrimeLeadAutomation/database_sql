-- ============================================================
-- PrimeLead Automation
-- Banco completo - MySQL 8.0
-- Baseado na modelagem db_service(1).mwb
-- + versionamento imutavel da configuracao de score
-- ============================================================

CREATE DATABASE IF NOT EXISTS `PrimeLeadAutomation`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `PrimeLeadAutomation`;

SET NAMES utf8mb4;

-- ============================================================
-- 1. EMPRESA
-- ============================================================
CREATE TABLE `empresa` (
    `id_empresa` INT NOT NULL AUTO_INCREMENT,
    `nome_empresa` VARCHAR(45) NULL,
    `segmento` VARCHAR(216) NULL,
    PRIMARY KEY (`id_empresa`)
) ENGINE=InnoDB;

-- ============================================================
-- 2. USUARIO
-- ============================================================
CREATE TABLE `usuario` (
    `id_usuario` INT NOT NULL AUTO_INCREMENT,
    `email` VARCHAR(216) NULL,
    `senha` VARCHAR(216) NULL,
    `nome` VARCHAR(216) NULL,
    `cargo` ENUM('gestor','analista') NULL,
    `fk_empresa` INT NOT NULL,
    PRIMARY KEY (`id_usuario`),
    KEY `fk_usuario_empresa1_idx` (`fk_empresa`),
    CONSTRAINT `fk_usuario_empresa1`
        FOREIGN KEY (`fk_empresa`)
        REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- ============================================================
-- 3. POSSIVEL CLIENTE
-- ============================================================
CREATE TABLE `possivel_cliente` (
    `id_possivel_cliente` INT NOT NULL AUTO_INCREMENT,
    `nome_cliente` VARCHAR(100) NULL,
    `CNPJ` VARCHAR(14) NULL,
    `contato_telefone` VARCHAR(11) NULL,
    `contato_email` VARCHAR(216) NULL,
    `porte` ENUM('pequeno','medio','grande') NULL,
    `segmento` VARCHAR(216) NULL,
    `origem` VARCHAR(45) NULL,
    PRIMARY KEY (`id_possivel_cliente`)
) ENGINE=InnoDB;

-- ============================================================
-- 4. CATALOGO DE PREFERENCIAS
-- ============================================================
CREATE TABLE `preferencia_cliente` (
    `id_preferencia_cliente` INT NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(45) NULL,
    `chave` VARCHAR(50) NULL,
    PRIMARY KEY (`id_preferencia_cliente`),
    UNIQUE KEY `uq_preferencia_cliente_chave` (`chave`)
) ENGINE=InnoDB;

-- ============================================================
-- 5. VERSAO DA CONFIGURACAO DE SCORE
-- ============================================================
CREATE TABLE `versao_configuracao_score` (
    `id_versao_configuracao_score` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `numero_versao` INT NOT NULL,
    `status_versao` ENUM('RASCUNHO','PUBLICADA') NOT NULL DEFAULT 'RASCUNHO',
    `criado_em` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `publicado_em` DATETIME(6) NULL,
    `criado_por` INT NULL,
    `observacao` VARCHAR(500) NULL,
    PRIMARY KEY (`id_versao_configuracao_score`),
    UNIQUE KEY `uq_versao_score_empresa_numero` (`fk_empresa`, `numero_versao`),
    KEY `ix_versao_score_empresa_status` (`fk_empresa`, `status_versao`),
    CONSTRAINT `fk_versao_score_empresa`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_versao_score_usuario`
        FOREIGN KEY (`criado_por`) REFERENCES `usuario` (`id_usuario`)
        ON UPDATE NO ACTION ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 6. MATCH EMPRESA x LEAD
-- ============================================================
CREATE TABLE `match_empresa_lead` (
    `id_match` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `fk_possivel_cliente` INT NOT NULL,
    `score` INT NULL,
    `fk_versao_configuracao_score` INT NULL,
    `score_versao` VARCHAR(64) NULL,
    `calculado_em` DATETIME(6) NULL,
    PRIMARY KEY (`id_match`),
    UNIQUE KEY `uq_match_empresa_lead` (`fk_empresa`, `fk_possivel_cliente`),
    KEY `fk_empresa_has_possivel_cliente_possivel_cliente1_idx` (`fk_possivel_cliente`),
    KEY `fk_empresa_has_possivel_cliente_empresa1_idx` (`fk_empresa`),
    KEY `ix_match_versao_configuracao_score` (`fk_versao_configuracao_score`),
    CONSTRAINT `fk_empresa_has_possivel_cliente_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_empresa_has_possivel_cliente_possivel_cliente1`
        FOREIGN KEY (`fk_possivel_cliente`) REFERENCES `possivel_cliente` (`id_possivel_cliente`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_match_versao_configuracao_score`
        FOREIGN KEY (`fk_versao_configuracao_score`)
        REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- ============================================================
-- 7. CLASSIFICACAO CONSOLIDADA DO MATCH
--
-- Substitui as cinco tabelas: bom, medio, ruim, aprovado e negado.
-- Existe uma classificacao atual para cada match.
-- ============================================================
CREATE TABLE `classificacao_match` (
    `id_classificacao_match` INT NOT NULL AUTO_INCREMENT,
    `fk_match` INT NOT NULL,
    `classificacao` ENUM('bom','medio','ruim','aprovado','negado') NOT NULL,
    `atualizado_em` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (`id_classificacao_match`),
    UNIQUE KEY `uq_classificacao_match` (`fk_match`),
    CONSTRAINT `fk_classificacao_match_match`
        FOREIGN KEY (`fk_match`) REFERENCES `match_empresa_lead` (`id_match`)
        ON UPDATE NO ACTION ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 8. CRITERIO / PESO POR EMPRESA E VERSAO
-- ============================================================
CREATE TABLE `criterio_preferencia` (
    `id_criterio_empresa` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `fk_preferencia` INT NOT NULL,
    `peso_preferencia` FLOAT NULL,
    `versao_peso` INT NULL,
    `atualizado_em` DATETIME NULL,
    `fk_versao_configuracao_score` INT NULL,
    PRIMARY KEY (`id_criterio_empresa`),
    UNIQUE KEY `uq_criterio_empresa_preferencia_versao`
        (`fk_empresa`, `fk_preferencia`, `fk_versao_configuracao_score`),
    KEY `fk_empresa_has_preferencia_cliente_empresa1_idx` (`fk_empresa`),
    KEY `fk_empresa_has_preferencia_cliente_preferencia_cliente1_idx` (`fk_preferencia`),
    KEY `ix_criterio_preferencia_versao` (`fk_versao_configuracao_score`),
    CONSTRAINT `fk_empresa_has_preferencia_cliente_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_empresa_has_preferencia_cliente_preferencia_cliente1`
        FOREIGN KEY (`fk_preferencia`) REFERENCES `preferencia_cliente` (`id_preferencia_cliente`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_criterio_preferencia_versao`
        FOREIGN KEY (`fk_versao_configuracao_score`)
        REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `ck_criterio_preferencia_peso`
        CHECK (`peso_preferencia` IS NULL OR (`peso_preferencia` >= 0 AND `peso_preferencia` <= 100))
) ENGINE=InnoDB;

-- ============================================================
-- 9. PESO POR CANAL DE ORIGEM
-- ============================================================
CREATE TABLE `origem_peso` (
    `id_origem_peso` INT NOT NULL AUTO_INCREMENT,
    `versao_peso` INT NOT NULL,
    `fk_empresa` INT NOT NULL,
    `atualizado_em` DATETIME NULL,
    `canal` VARCHAR(45) NULL,
    `peso` FLOAT NULL,
    `fk_versao_configuracao_score` INT NULL,
    PRIMARY KEY (`id_origem_peso`),
    UNIQUE KEY `uq_origem_peso_empresa_versao_canal`
        (`fk_empresa`, `fk_versao_configuracao_score`, `canal`),
    KEY `fk_origem_peso_empresa1_idx` (`fk_empresa`),
    KEY `ix_origem_peso_versao` (`fk_versao_configuracao_score`),
    CONSTRAINT `fk_origem_peso_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_origem_peso_versao`
        FOREIGN KEY (`fk_versao_configuracao_score`)
        REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `ck_origem_peso_peso`
        CHECK (`peso` IS NULL OR (`peso` >= 0 AND `peso` <= 100))
) ENGINE=InnoDB;

-- ============================================================
-- 10. PLANO DE ASSINATURA
-- ============================================================
CREATE TABLE `plano_assinatura` (
    `id_plano_assinatura` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `nome_plano` ENUM('standard','premium') NULL,
    PRIMARY KEY (`id_plano_assinatura`),
    UNIQUE KEY `uq_plano_assinatura_empresa` (`fk_empresa`),
    KEY `fk_plano_assinatura_empresa1_idx` (`fk_empresa`),
    CONSTRAINT `fk_plano_assinatura_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- ============================================================
-- 11. DADOS INICIAIS DO CATALOGO DE FATORES
--
-- Os quatro fatores sao fixos conforme a modelagem/front:
-- fit, engajamento, comportamento e origem.
-- ============================================================
INSERT INTO `preferencia_cliente`
    (`id_preferencia_cliente`, `nome`, `chave`)
VALUES
    (1, 'Fit', 'fit'),
    (2, 'Engajamento', 'engajamento'),
    (3, 'Comportamento', 'comportamento'),
    (4, 'Origem', 'origem');

-- ============================================================
-- 12. PROCEDURE DE PUBLICACAO
--
-- Uma versao somente pode ser publicada se:
--   - estiver em RASCUNHO;
--   - pertencer a uma empresa;
--   - possuir exatamente os quatro fatores;
--   - os quatro pesos somarem 100.
--
-- Os canais de origem nao precisam somar 100, pois sao pesos
-- independentes dos canais de aquisicao.
-- ============================================================
DELIMITER $$

CREATE PROCEDURE `publicar_configuracao_score` (
    IN p_id_versao INT
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_empresa INT;
    DECLARE v_qtd_fatores INT DEFAULT 0;
    DECLARE v_soma_fatores DECIMAL(10,2) DEFAULT 0;

    SELECT
        `status_versao`,
        `fk_empresa`
    INTO
        v_status,
        v_empresa
    FROM `versao_configuracao_score`
    WHERE `id_versao_configuracao_score` = p_id_versao
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Versao de configuracao nao encontrada.';
    END IF;

    IF v_status <> 'RASCUNHO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Somente uma versao RASCUNHO pode ser publicada.';
    END IF;

    SELECT COUNT(DISTINCT cp.`fk_preferencia`),
           COALESCE(SUM(cp.`peso_preferencia`), 0)
    INTO v_qtd_fatores, v_soma_fatores
    FROM `criterio_preferencia` cp
    INNER JOIN `preferencia_cliente` pc
        ON pc.`id_preferencia_cliente` = cp.`fk_preferencia`
    WHERE cp.`fk_versao_configuracao_score` = p_id_versao
      AND cp.`fk_empresa` = v_empresa
      AND pc.`chave` IN (
          'fit',
          'engajamento',
          'comportamento',
          'origem'
      );

    IF v_qtd_fatores <> 4 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A configuracao precisa possuir os quatro fatores de score.';
    END IF;

    IF ABS(v_soma_fatores - 100) > 0.001 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A soma dos quatro pesos deve ser igual a 100.';
    END IF;

    UPDATE `versao_configuracao_score`
    SET
        `status_versao` = 'PUBLICADA',
        `publicado_em` = CURRENT_TIMESTAMP(6)
    WHERE `id_versao_configuracao_score` = p_id_versao;

END$$

DELIMITER ;

-- ============================================================
-- 13. TRIGGERS DE IMUTABILIDADE
-- ============================================================
DELIMITER $$

CREATE TRIGGER `trg_criterio_preferencia_no_update_publicada`
BEFORE UPDATE ON `criterio_preferencia`
FOR EACH ROW
BEGIN
    IF OLD.`fk_versao_configuracao_score` IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM `versao_configuracao_score`
           WHERE `id_versao_configuracao_score`
                 = OLD.`fk_versao_configuracao_score`
             AND `status_versao` = 'PUBLICADA'
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido alterar criterios de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_criterio_preferencia_no_delete_publicada`
BEFORE DELETE ON `criterio_preferencia`
FOR EACH ROW
BEGIN
    IF OLD.`fk_versao_configuracao_score` IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM `versao_configuracao_score`
           WHERE `id_versao_configuracao_score`
                 = OLD.`fk_versao_configuracao_score`
             AND `status_versao` = 'PUBLICADA'
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido excluir criterios de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_origem_peso_no_update_publicada`
BEFORE UPDATE ON `origem_peso`
FOR EACH ROW
BEGIN
    IF OLD.`fk_versao_configuracao_score` IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM `versao_configuracao_score`
           WHERE `id_versao_configuracao_score`
                 = OLD.`fk_versao_configuracao_score`
             AND `status_versao` = 'PUBLICADA'
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido alterar pesos de origem de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_origem_peso_no_delete_publicada`
BEFORE DELETE ON `origem_peso`
FOR EACH ROW
BEGIN
    IF OLD.`fk_versao_configuracao_score` IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM `versao_configuracao_score`
           WHERE `id_versao_configuracao_score`
                 = OLD.`fk_versao_configuracao_score`
             AND `status_versao` = 'PUBLICADA'
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido excluir pesos de origem de uma versao publicada.';
    END IF;
END$$

CREATE TRIGGER `trg_versao_score_no_update_publicada`
BEFORE UPDATE ON `versao_configuracao_score`
FOR EACH ROW
BEGIN
    IF OLD.`status_versao` = 'PUBLICADA' THEN
        IF NEW.`status_versao` <> 'PUBLICADA'
           OR NEW.`fk_empresa` <> OLD.`fk_empresa`
           OR NEW.`numero_versao` <> OLD.`numero_versao`
           OR NOT (NEW.`criado_por` <=> OLD.`criado_por`)
           OR NOT (NEW.`observacao` <=> OLD.`observacao`) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Versoes publicadas sao imutaveis.';
        END IF;
    END IF;
END$$

CREATE TRIGGER `trg_versao_score_no_delete_publicada`
BEFORE DELETE ON `versao_configuracao_score`
FOR EACH ROW
BEGIN
    IF OLD.`status_versao` = 'PUBLICADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao e permitido excluir uma versao publicada.';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 14. CONSULTA DE AUDITORIA
-- ============================================================
-- SELECT
--     mel.id_match,
--     mel.fk_empresa,
--     mel.fk_possivel_cliente,
--     mel.score,
--     mel.fk_versao_configuracao_score,
--     vcs.numero_versao AS versao_pesos,
--     mel.score_versao AS versao_regressao,
--     mel.calculado_em
-- FROM match_empresa_lead mel
-- LEFT JOIN versao_configuracao_score vcs
--     ON vcs.id_versao_configuracao_score =
--        mel.fk_versao_configuracao_score;

-- ============================================================
-- FIM
-- ============================================================
