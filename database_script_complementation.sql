-- PrimeLeadAutomation / MySQL 8.0
-- Executar UMA vez, após primelead_automation_script.sql, com backup e janela de manutenção.
-- Não recria tabelas, não apaga dados e não preenche informações desconhecidas.
USE `PrimeLeadAutomation`;

-- Falha cedo se houver emails duplicados preexistentes (corrigir antes da migração).
ALTER TABLE `usuario` ADD UNIQUE KEY `uq_usuario_email` (`email`);

ALTER TABLE `empresa`
  ADD COLUMN `funcionarios` INT NULL,
  ADD COLUMN `ticket_medio` DECIMAL(15,2) NULL,
  ADD COLUMN `ciclo_venda` ENUM('curto','medio','longo') NULL,
  ADD COLUMN `canais` JSON NULL,
  ADD COLUMN `site` VARCHAR(255) NULL,
  ADD CONSTRAINT `ck_empresa_funcionarios` CHECK (`funcionarios` IS NULL OR `funcionarios` >= 0),
  ADD CONSTRAINT `ck_empresa_ticket` CHECK (`ticket_medio` IS NULL OR `ticket_medio` >= 0);

ALTER TABLE `usuario`
  ADD COLUMN `cor` VARCHAR(7) NULL,
  ADD COLUMN `meta` INT NOT NULL DEFAULT 0,
  ADD COLUMN `fechados` INT NOT NULL DEFAULT 0,
  ADD COLUMN `taxa_conversao` DECIMAL(5,4) NOT NULL DEFAULT 0,
  ADD COLUMN `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN `onboarding_concluido_em` DATETIME(6) NULL,
  ADD COLUMN `onboarding_pulado` BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN `preferencias` JSON NULL,
  ADD CONSTRAINT `ck_usuario_meta` CHECK (`meta` >= 0 AND `fechados` >= 0),
  ADD CONSTRAINT `ck_usuario_taxa` CHECK (`taxa_conversao` BETWEEN 0 AND 1),
  ADD UNIQUE KEY `uq_usuario_empresa_identidade` (`id_usuario`, `fk_empresa`);

ALTER TABLE `possivel_cliente`
  ADD COLUMN `nome_contato` VARCHAR(216) NULL,
  ADD COLUMN `cargo_contato` VARCHAR(216) NULL,
  ADD COLUMN `porte_descricao` VARCHAR(100) NULL;

-- Dados comerciais e sinais pertencem ao match da empresa, não ao lead global.
ALTER TABLE `match_empresa_lead`
  ADD COLUMN `fk_usuario_responsavel` INT NULL,
  ADD COLUMN `valor_potencial` DECIMAL(15,2) NULL,
  ADD COLUMN `status_comercial` VARCHAR(100) NULL,
  ADD COLUMN `fit_base` TINYINT UNSIGNED NULL,
  ADD COLUMN `engajamento` TINYINT UNSIGNED NULL,
  ADD COLUMN `comportamento` TINYINT UNSIGNED NULL,
  ADD COLUMN `nota_origem` TINYINT UNSIGNED NULL,
  ADD COLUMN `sinais` JSON NULL,
  ADD COLUMN `atualizado_em` DATETIME(6) NULL,
  ADD KEY `ix_match_responsavel_empresa` (`fk_usuario_responsavel`, `fk_empresa`),
  ADD CONSTRAINT `fk_match_responsavel_mesma_empresa`
    FOREIGN KEY (`fk_usuario_responsavel`, `fk_empresa`)
    REFERENCES `usuario` (`id_usuario`, `fk_empresa`),
  ADD CONSTRAINT `ck_match_valor` CHECK (`valor_potencial` IS NULL OR `valor_potencial` >= 0),
  ADD CONSTRAINT `ck_match_fit` CHECK (`fit_base` IS NULL OR `fit_base` <= 100),
  ADD CONSTRAINT `ck_match_engajamento` CHECK (`engajamento` IS NULL OR `engajamento` <= 100),
  ADD CONSTRAINT `ck_match_comportamento` CHECK (`comportamento` IS NULL OR `comportamento` <= 100),
  ADD CONSTRAINT `ck_match_origem` CHECK (`nota_origem` IS NULL OR `nota_origem` <= 100);

-- O nome de plano legado permanece compatível com registros existentes.
ALTER TABLE `plano_assinatura`
  MODIFY COLUMN `nome_plano` ENUM('standard','premium','corporativo') NULL,
  ADD COLUMN `periodicidade` ENUM('mensal','anual') NOT NULL DEFAULT 'mensal',
  ADD COLUMN `teste_ate` DATETIME(6) NULL;

-- Detalhes publicados são instantâneos imutáveis, associados à versão existente.
CREATE TABLE `configuracao_score_detalhe` (
  `fk_versao_configuracao_score` INT NOT NULL,
  `limite_otimo` TINYINT UNSIGNED NOT NULL,
  `limite_bom` TINYINT UNSIGNED NOT NULL,
  `icp_segmentos` JSON NOT NULL,
  `icp_portes` JSON NOT NULL,
  `icp_orcamento_min` DECIMAL(15,2) NOT NULL,
  `valores` JSON NOT NULL,
  PRIMARY KEY (`fk_versao_configuracao_score`),
  CONSTRAINT `fk_detalhe_versao` FOREIGN KEY (`fk_versao_configuracao_score`)
    REFERENCES `versao_configuracao_score` (`id_versao_configuracao_score`),
  CONSTRAINT `ck_detalhe_limites` CHECK (`limite_bom` <= `limite_otimo` AND `limite_otimo` <= 100),
  CONSTRAINT `ck_detalhe_orcamento` CHECK (`icp_orcamento_min` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `atividade_lead` (
  `id_atividade` INT NOT NULL AUTO_INCREMENT,
  `fk_match` INT NOT NULL,
  `fk_usuario` INT NULL,
  `tipo` ENUM('email','site','origem','acao') NOT NULL,
  `descricao` VARCHAR(500) NOT NULL,
  `ocorrido_em` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id_atividade`),
  KEY `ix_atividade_match_data` (`fk_match`, `ocorrido_em`),
  CONSTRAINT `fk_atividade_match` FOREIGN KEY (`fk_match`) REFERENCES `match_empresa_lead` (`id_match`) ON DELETE CASCADE,
  CONSTRAINT `fk_atividade_usuario` FOREIGN KEY (`fk_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER `trg_detalhe_no_insert_publicada` BEFORE INSERT ON `configuracao_score_detalhe`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score` WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score` AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Versao publicada nao aceita novos detalhes.';
  END IF;
END$$
CREATE TRIGGER `trg_detalhe_no_update_publicada` BEFORE UPDATE ON `configuracao_score_detalhe`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score` WHERE `id_versao_configuracao_score` IN (OLD.`fk_versao_configuracao_score`, NEW.`fk_versao_configuracao_score`) AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalhes publicados sao imutaveis.';
  END IF;
END$$
CREATE TRIGGER `trg_detalhe_no_delete_publicada` BEFORE DELETE ON `configuracao_score_detalhe`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score` WHERE `id_versao_configuracao_score` = OLD.`fk_versao_configuracao_score` AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalhes publicados nao podem ser excluidos.';
  END IF;
END$$
CREATE TRIGGER `trg_criterio_no_insert_publicada` BEFORE INSERT ON `criterio_preferencia`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score` WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score` AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Versao publicada nao aceita novos fatores.';
  END IF;
END$$
CREATE TRIGGER `trg_origem_no_insert_publicada` BEFORE INSERT ON `origem_peso`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score` WHERE `id_versao_configuracao_score` = NEW.`fk_versao_configuracao_score` AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Versao publicada nao aceita novos canais.';
  END IF;
END$$
-- Substitui os triggers antigos para vedar também mover linhas DE um rascunho
-- PARA uma versão publicada (além de alterar uma linha já publicada).
DROP TRIGGER IF EXISTS `trg_criterio_preferencia_no_update_publicada`$$
CREATE TRIGGER `trg_criterio_preferencia_no_update_publicada` BEFORE UPDATE ON `criterio_preferencia`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score`
             WHERE `id_versao_configuracao_score` IN (OLD.`fk_versao_configuracao_score`, NEW.`fk_versao_configuracao_score`)
               AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao e permitido alterar fatores de uma versao publicada.';
  END IF;
END$$
DROP TRIGGER IF EXISTS `trg_origem_peso_no_update_publicada`$$
CREATE TRIGGER `trg_origem_peso_no_update_publicada` BEFORE UPDATE ON `origem_peso`
FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM `versao_configuracao_score`
             WHERE `id_versao_configuracao_score` IN (OLD.`fk_versao_configuracao_score`, NEW.`fk_versao_configuracao_score`)
               AND `status_versao` = 'PUBLICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao e permitido alterar origem de uma versao publicada.';
  END IF;
END$$
DELIMITER ;
