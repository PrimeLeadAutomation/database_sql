-- ============================================================
-- PrimeLead Automation
-- Massa de dados para desenvolvimento e testes funcionais
--
-- Observacoes:
--   - Esta massa utiliza os IDs 1 a 3 para facilitar os testes.
--   - As senhas abaixo sao de uso exclusivo em ambiente local.
--   - Esta massa foi ajustada ao script_fiel.sql, sem versionamento
--     de configuracao de score ou campos adicionados por essa proposta.
--   - A tabela criterio_preferencia permanece omitida, conforme a massa original.
-- ============================================================

USE `PrimeLeadAutomation`;

SET NAMES utf8mb4;
START TRANSACTION;

-- ============================================================
-- 1. EMPRESA
-- ============================================================
INSERT INTO `empresa`
    (`id_empresa`, `nome_empresa`, `segmento`)
VALUES
    (1, 'PrimeLead Tecnologia Ltda', 'Tecnologia e servicos B2B')
ON DUPLICATE KEY UPDATE
    `nome_empresa` = VALUES(`nome_empresa`),
    `segmento` = VALUES(`segmento`);

-- ============================================================
-- 2. USUARIOS
-- ============================================================
INSERT INTO `usuario`
    (`id_usuario`, `email`, `senha`, `nome`, `cargo`, `fk_empresa`)
VALUES
    (1, 'ricardo.bennet@primelead.local', 'Senha@123', 'Ricardo Bennet', 'gestor', 1),
    (2, 'maria.fernandes@primelead.local', 'Senha@123', 'Maria Fernandes', 'analista', 1)
ON DUPLICATE KEY UPDATE
    `email` = VALUES(`email`),
    `senha` = VALUES(`senha`),
    `nome` = VALUES(`nome`),
    `cargo` = VALUES(`cargo`),
    `fk_empresa` = VALUES(`fk_empresa`);

-- ============================================================
-- 3. CATALOGO DE PREFERENCIAS EMPRESARIAIS
-- ============================================================
-- Os quatro fatores iniciais (Fit, Engajamento, Comportamento e Origem)
-- sao inseridos pelo script_fiel.sql. Aqui entram caracteristicas adicionais.
INSERT INTO `preferencia_cliente`
    (`id_preferencia_cliente`, `nome`, `chave`)
VALUES
    (5, 'Inovadora', 'inovadora'),
    (6, 'Conservadora', 'conservadora'),
    (7, 'Consolidada', 'consolidada'),
    (8, 'Recem criada', 'recem_criada'),
    (9, 'Em crescimento', 'em_crescimento'),
    (10, 'Orientada a dados', 'orientada_a_dados'),
    (11, 'Digital em transformacao', 'digital_em_transformacao')
ON DUPLICATE KEY UPDATE
    `nome` = VALUES(`nome`),
    `chave` = VALUES(`chave`);

-- ============================================================
-- 4. PLANO DE ASSINATURA
-- ============================================================
-- A massa carrega um plano de exemplo para a empresa de teste.
INSERT INTO `plano_assinatura`
    (`id_plano_assinatura`, `fk_empresa`, `nome_plano`)
VALUES
    (1, 1, 'standard')
ON DUPLICATE KEY UPDATE
    `fk_empresa` = VALUES(`fk_empresa`),
    `nome_plano` = VALUES(`nome_plano`);

-- ============================================================
-- 5. PESOS POR CANAL DE ORIGEM
-- ============================================================
INSERT INTO `origem_peso`
    (`id_origem_peso`, `versao_peso`, `fk_empresa`, `atualizado_em`,
     `canal`, `peso`)
VALUES
    (1, 1, 1, '2026-01-15 09:00:00', 'indicacao', 30.00),
    (2, 1, 1, '2026-01-15 09:00:00', 'site', 20.00),
    (3, 1, 1, '2026-01-15 09:00:00', 'linkedin', 25.00),
    (4, 1, 1, '2026-01-15 09:00:00', 'evento', 15.00),
    (5, 1, 1, '2026-01-15 09:00:00', 'prospeccao_ativa', 10.00)
ON DUPLICATE KEY UPDATE
    `versao_peso` = VALUES(`versao_peso`),
    `fk_empresa` = VALUES(`fk_empresa`),
    `atualizado_em` = VALUES(`atualizado_em`),
    `canal` = VALUES(`canal`),
    `peso` = VALUES(`peso`);

-- ============================================================
-- 6. DADOS DE APOIO PARA CLASSIFICACAO DE MATCH
-- ============================================================
-- Os registros abaixo existem somente para que classificacao_match
-- tenha matches validos para os testes de score.
INSERT INTO `possivel_cliente`
    (`id_possivel_cliente`, `nome_cliente`, `CNPJ`, `contato_telefone`,
     `contato_email`, `porte`, `segmento`, `origem`)
VALUES
    (1, 'Alfa Contabilidade e Gestao', '12345678000101', '11987654321',
     'contato@alfacontabilidade.local', 'pequeno', 'Servicos contabeis', 'indicacao'),
    (2, 'Beta Comercio Digital', '23456789000102', '11987654322',
     'contato@betacomercio.local', 'medio', 'Comercio varejista', 'site'),
    (3, 'Gamma Tech Solutions', '34567890000103', '11987654323',
     'contato@gammatech.local', 'medio', 'Tecnologia', 'linkedin')
ON DUPLICATE KEY UPDATE
    `nome_cliente` = VALUES(`nome_cliente`),
    `CNPJ` = VALUES(`CNPJ`),
    `contato_telefone` = VALUES(`contato_telefone`),
    `contato_email` = VALUES(`contato_email`),
    `porte` = VALUES(`porte`),
    `segmento` = VALUES(`segmento`),
    `origem` = VALUES(`origem`);

INSERT INTO `match_empresa_lead`
    (`id_match`, `fk_empresa`, `fk_possivel_cliente`, `score`)
VALUES
    (1, 1, 1, 86),
    (2, 1, 2, 63),
    (3, 1, 3, 38)
ON DUPLICATE KEY UPDATE
    `fk_empresa` = VALUES(`fk_empresa`),
    `fk_possivel_cliente` = VALUES(`fk_possivel_cliente`),
    `score` = VALUES(`score`);

INSERT INTO `classificacao_match`
    (`id_classificacao_match`, `fk_match`, `fk_empresa`, `fk_possivel_cliente`, `classificacao`)
VALUES
    (1, 1, 1, 1, 'aprovado'),
    (2, 2, 1, 2, 'bom'),
    (3, 3, 1, 3, 'ruim')
ON DUPLICATE KEY UPDATE
    `fk_match` = VALUES(`fk_match`),
    `fk_empresa` = VALUES(`fk_empresa`),
    `fk_possivel_cliente` = VALUES(`fk_possivel_cliente`),
    `classificacao` = VALUES(`classificacao`);

COMMIT;

-- ============================================================
-- FIM DA MASSA
-- ============================================================