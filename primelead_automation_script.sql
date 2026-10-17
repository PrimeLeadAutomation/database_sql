-- ============================================================
-- PrimeLead Automation - script_fiel
-- MySQL 8.0
-- Baseado na modelagem db_service(1).mwb e na documentacao fornecida.
-- Adaptacoes solicitadas pelo usuario: AUTO_INCREMENT nas PKs e
-- consolidacao das cinco tabelas de classificacao em uma tabela.
-- Nao inclui versionamento de configuracao nem regras adicionais inferidas.
-- ============================================================

CREATE DATABASE IF NOT EXISTS `PrimeLeadAutomation`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `PrimeLeadAutomation`;
SET NAMES utf8mb4;

-- 1. EMPRESA
CREATE TABLE `empresa` (
    `id_empresa` INT NOT NULL AUTO_INCREMENT,
    `nome_empresa` VARCHAR(45) NULL,
    `segmento` VARCHAR(216) NULL,
    PRIMARY KEY (`id_empresa`)
) ENGINE=InnoDB;

-- 2. USUARIO
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
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- 3. POSSIVEL CLIENTE
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

-- 4. MATCH EMPRESA x LEAD
CREATE TABLE `match_empresa_lead` (
    `id_match` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `fk_possivel_cliente` INT NOT NULL,
    `score` INT NULL,
    PRIMARY KEY (`id_match`),
    KEY `fk_empresa_has_possivel_cliente_possivel_cliente1_idx` (`fk_possivel_cliente`),
    KEY `fk_empresa_has_possivel_cliente_empresa1_idx` (`fk_empresa`),
    CONSTRAINT `fk_empresa_has_possivel_cliente_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_empresa_has_possivel_cliente_possivel_cliente1`
        FOREIGN KEY (`fk_possivel_cliente`) REFERENCES `possivel_cliente` (`id_possivel_cliente`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- 5. CLASSIFICACAO CONSOLIDADA
-- Consolidacao solicitada das tabelas bom, medio, ruim, aprovado e negado.
CREATE TABLE `classificacao_match` (
    `id_classificacao_match` INT NOT NULL AUTO_INCREMENT,
    `fk_match` INT NOT NULL,
    `fk_empresa` INT NOT NULL,
    `fk_possivel_cliente` INT NOT NULL,
    `classificacao` ENUM('bom','medio','ruim','aprovado','negado') NOT NULL,
    PRIMARY KEY (`id_classificacao_match`),
    KEY `ix_classificacao_match_match` (`fk_match`),
    KEY `ix_classificacao_match_empresa` (`fk_empresa`),
    KEY `ix_classificacao_match_cliente` (`fk_possivel_cliente`),
    CONSTRAINT `fk_classificacao_match_match`
        FOREIGN KEY (`fk_match`) REFERENCES `match_empresa_lead` (`id_match`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_classificacao_match_empresa`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_classificacao_match_cliente`
        FOREIGN KEY (`fk_possivel_cliente`) REFERENCES `possivel_cliente` (`id_possivel_cliente`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- 6. PREFERENCIA CLIENTE
CREATE TABLE `preferencia_cliente` (
    `id_preferencia_cliente` INT NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(45) NULL,
    `chave` VARCHAR(50) NULL,
    PRIMARY KEY (`id_preferencia_cliente`)
) ENGINE=InnoDB;

-- 7. CRITERIO / PESO POR EMPRESA
CREATE TABLE `criterio_preferencia` (
    `id_criterio_empresa` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `fk_preferencia` INT NOT NULL,
    `peso_preferencia` FLOAT NULL,
    `versao_peso` INT NULL,
    `atualizado_em` DATETIME NULL,
    PRIMARY KEY (`id_criterio_empresa`),
    KEY `fk_empresa_has_preferencia_cliente_empresa1_idx` (`fk_empresa`),
    KEY `fk_empresa_has_preferencia_cliente_preferencia_cliente1_idx` (`fk_preferencia`),
    CONSTRAINT `fk_empresa_has_preferencia_cliente_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT `fk_empresa_has_preferencia_cliente_preferencia_cliente1`
        FOREIGN KEY (`fk_preferencia`) REFERENCES `preferencia_cliente` (`id_preferencia_cliente`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- 8. PESO POR CANAL DE ORIGEM
CREATE TABLE `origem_peso` (
    `id_origem_peso` INT NOT NULL AUTO_INCREMENT,
    `versao_peso` INT NOT NULL,
    `fk_empresa` INT NOT NULL,
    `atualizado_em` DATETIME NULL,
    `canal` VARCHAR(45) NULL,
    `peso` FLOAT NULL,
    PRIMARY KEY (`id_origem_peso`),
    KEY `fk_origem_peso_empresa1_idx` (`fk_empresa`),
    CONSTRAINT `fk_origem_peso_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- 9. PLANO DE ASSINATURA
CREATE TABLE `plano_assinatura` (
    `id_plano_assinatura` INT NOT NULL AUTO_INCREMENT,
    `fk_empresa` INT NOT NULL,
    `nome_plano` ENUM('standard','premium') NULL,
    PRIMARY KEY (`id_plano_assinatura`),
    KEY `fk_plano_assinatura_empresa1_idx` (`fk_empresa`),
    CONSTRAINT `fk_plano_assinatura_empresa1`
        FOREIGN KEY (`fk_empresa`) REFERENCES `empresa` (`id_empresa`)
        ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- Dados iniciais do catalogo de fatores descritos na documentacao.
INSERT INTO `preferencia_cliente` (`nome`, `chave`) VALUES
    ('Fit', 'fit'),
    ('Engajamento', 'engajamento'),
    ('Comportamento', 'comportamento'),
    ('Origem', 'origem');

-- FIM DO SCRIPT