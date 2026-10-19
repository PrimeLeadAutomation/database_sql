-- ============================================================
-- PrimeLead Automation
-- Massa de dados para desenvolvimento e testes funcionais
--
-- Observacoes:
--   - Esta massa utiliza os IDs 1 a 3 para facilitar os testes.
--   - As senhas abaixo sao de uso exclusivo em ambiente local.
--   - Esta massa contempla os campos adicionados por
--     database_script_complementation.sql.
--   - A massa inclui uma versao RASCUNHO completa, com seus quatro fatores,
--     pesos de origem e detalhes de configuracao.
-- ============================================================

USE `PrimeLeadAutomation`;

SET NAMES utf8mb4;
START TRANSACTION;

-- ============================================================
-- 1. EMPRESA
-- ============================================================
INSERT INTO `empresa`
    (`id_empresa`, `nome_empresa`, `segmento`, `funcionarios`, `ticket_medio`,
     `ciclo_venda`, `canais`, `site`)
VALUES
    (1, 'PrimeLead Tecnologia Ltda', 'Tecnologia e servicos B2B', 42, 18500.00,
     'medio', JSON_ARRAY('indicacao', 'site', 'linkedin', 'evento'),
     'https://www.primelead.local')
ON DUPLICATE KEY UPDATE
    `nome_empresa` = VALUES(`nome_empresa`),
    `segmento` = VALUES(`segmento`),
    `funcionarios` = VALUES(`funcionarios`),
    `ticket_medio` = VALUES(`ticket_medio`),
    `ciclo_venda` = VALUES(`ciclo_venda`),
    `canais` = VALUES(`canais`),
    `site` = VALUES(`site`);

-- ============================================================
-- 2. USUARIOS
-- ============================================================
INSERT INTO `usuario`
    (`id_usuario`, `email`, `senha`, `nome`, `cargo`, `fk_empresa`, `cor`,
     `meta`, `fechados`, `taxa_conversao`, `ativo`, `onboarding_concluido_em`,
     `onboarding_pulado`, `preferencias`)
VALUES
    (1, 'ricardo.bennet@primelead.local', 'Senha@123', 'Ricardo Bennet', 'gestor', 1,
     '#2563EB', 30, 12, 0.4000, TRUE, '2026-01-10 08:30:00.000000', FALSE,
     JSON_OBJECT('fit', TRUE, 'engajamento', TRUE, 'comportamento', TRUE, 'origem', TRUE)),
    (2, 'maria.fernandes@primelead.local', 'Senha@123', 'Maria Fernandes', 'analista', 1,
     '#7C3AED', 20, 7, 0.3500, TRUE, '2026-01-11 09:00:00.000000', FALSE,
     JSON_OBJECT('fit', TRUE, 'engajamento', TRUE, 'comportamento', FALSE, 'origem', TRUE))
ON DUPLICATE KEY UPDATE
    `email` = VALUES(`email`),
    `senha` = VALUES(`senha`),
    `nome` = VALUES(`nome`),
    `cargo` = VALUES(`cargo`),
    `fk_empresa` = VALUES(`fk_empresa`),
    `cor` = VALUES(`cor`),
    `meta` = VALUES(`meta`),
    `fechados` = VALUES(`fechados`),
    `taxa_conversao` = VALUES(`taxa_conversao`),
    `ativo` = VALUES(`ativo`),
    `onboarding_concluido_em` = VALUES(`onboarding_concluido_em`),
    `onboarding_pulado` = VALUES(`onboarding_pulado`),
    `preferencias` = VALUES(`preferencias`);

-- ============================================================
-- 3. VERSAO DA CONFIGURACAO DE SCORE
-- ============================================================
INSERT INTO `versao_configuracao_score`
    (`id_versao_configuracao_score`, `fk_empresa`, `numero_versao`,
     `status_versao`, `criado_em`, `criado_por`, `observacao`)
VALUES
    (1, 1, 1, 'RASCUNHO', '2026-01-15 08:00:00.000000', 1,
     'Configuracao inicial para desenvolvimento e testes')
ON DUPLICATE KEY UPDATE
    `id_versao_configuracao_score` = `id_versao_configuracao_score`;

-- ============================================================
-- 4. CATALOGO DE PREFERENCIAS EMPRESARIAIS
-- ============================================================
-- Os quatro fatores iniciais (Fit, Engajamento, Comportamento e Origem)
-- sao inseridos pelo primelead_automation_script.sql. Aqui entram
-- caracteristicas adicionais.
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
-- 5. CRITERIOS DE SCORE POR VERSAO
-- ============================================================
INSERT INTO `criterio_preferencia`
    (`id_criterio_empresa`, `fk_empresa`, `fk_preferencia`, `peso_preferencia`,
     `versao_peso`, `atualizado_em`, `fk_versao_configuracao_score`)
VALUES
    (1, 1, 1, 35.00, 1, '2026-01-15 08:05:00', 1),
    (2, 1, 2, 25.00, 1, '2026-01-15 08:05:00', 1),
    (3, 1, 3, 25.00, 1, '2026-01-15 08:05:00', 1),
    (4, 1, 4, 15.00, 1, '2026-01-15 08:05:00', 1)
ON DUPLICATE KEY UPDATE
    `peso_preferencia` = VALUES(`peso_preferencia`),
    `versao_peso` = VALUES(`versao_peso`),
    `atualizado_em` = VALUES(`atualizado_em`);

-- ============================================================
-- 6. PLANO DE ASSINATURA
-- ============================================================
-- A massa carrega um plano de exemplo para a empresa de teste.
INSERT INTO `plano_assinatura`
    (`id_plano_assinatura`, `fk_empresa`, `nome_plano`, `periodicidade`, `teste_ate`)
VALUES
    (1, 1, 'standard', 'anual', '2026-02-15 23:59:59.000000')
ON DUPLICATE KEY UPDATE
    `fk_empresa` = VALUES(`fk_empresa`),
    `nome_plano` = VALUES(`nome_plano`),
    `periodicidade` = VALUES(`periodicidade`),
    `teste_ate` = VALUES(`teste_ate`);

-- ============================================================
-- 7. PESOS POR CANAL DE ORIGEM
-- ============================================================
INSERT INTO `origem_peso`
    (`id_origem_peso`, `versao_peso`, `fk_empresa`, `atualizado_em`,
     `canal`, `peso`, `fk_versao_configuracao_score`)
VALUES
    (1, 1, 1, '2026-01-15 09:00:00', 'indicacao', 30.00, 1),
    (2, 1, 1, '2026-01-15 09:00:00', 'site', 20.00, 1),
    (3, 1, 1, '2026-01-15 09:00:00', 'linkedin', 25.00, 1),
    (4, 1, 1, '2026-01-15 09:00:00', 'evento', 15.00, 1),
    (5, 1, 1, '2026-01-15 09:00:00', 'prospeccao_ativa', 10.00, 1)
ON DUPLICATE KEY UPDATE
    `versao_peso` = VALUES(`versao_peso`),
    `fk_empresa` = VALUES(`fk_empresa`),
    `atualizado_em` = VALUES(`atualizado_em`),
    `canal` = VALUES(`canal`),
    `peso` = VALUES(`peso`),
    `fk_versao_configuracao_score` = VALUES(`fk_versao_configuracao_score`);

-- ============================================================
-- 8. DADOS DE APOIO PARA CLASSIFICACAO DE MATCH
-- ============================================================
-- Os registros abaixo existem somente para que classificacao_match
-- tenha matches validos para os testes de score.
INSERT INTO `possivel_cliente`
    (`id_possivel_cliente`, `nome_cliente`, `CNPJ`, `contato_telefone`,
     `contato_email`, `porte`, `segmento`, `origem`, `nome_contato`,
     `cargo_contato`, `porte_descricao`)
VALUES
    (1, 'Alfa Contabilidade e Gestao', '12345678000101', '11987654321',
     'contato@alfacontabilidade.local', 'pequeno', 'Servicos contabeis', 'indicacao',
     'Ana Souza', 'Diretora financeira', 'Escritorio com ate 20 funcionarios'),
    (2, 'Beta Comercio Digital', '23456789000102', '11987654322',
     'contato@betacomercio.local', 'medio', 'Comercio varejista', 'site',
     'Bruno Lima', 'Gerente comercial', 'Operacao regional em expansao'),
    (3, 'Gamma Tech Solutions', '34567890000103', '11987654323',
     'contato@gammatech.local', 'medio', 'Tecnologia', 'linkedin',
     'Camila Alves', 'Head de receita', 'Empresa de tecnologia em crescimento')
ON DUPLICATE KEY UPDATE
    `nome_cliente` = VALUES(`nome_cliente`),
    `CNPJ` = VALUES(`CNPJ`),
    `contato_telefone` = VALUES(`contato_telefone`),
    `contato_email` = VALUES(`contato_email`),
    `porte` = VALUES(`porte`),
    `segmento` = VALUES(`segmento`),
    `origem` = VALUES(`origem`),
    `nome_contato` = VALUES(`nome_contato`),
    `cargo_contato` = VALUES(`cargo_contato`),
    `porte_descricao` = VALUES(`porte_descricao`);

INSERT INTO `match_empresa_lead`
    (`id_match`, `fk_empresa`, `fk_possivel_cliente`, `score`,
     `fk_versao_configuracao_score`, `score_versao`, `calculado_em`,
     `fk_usuario_responsavel`, `valor_potencial`, `status_comercial`,
     `fit_base`, `engajamento`, `comportamento`, `nota_origem`, `sinais`,
     `atualizado_em`)
VALUES
    (1, 1, 1, 86, 1, 'score-v1', '2026-01-20 10:15:00.000000', 1, 24000.00, 'em_negociacao', 92, 78, 84, 80,
     JSON_OBJECT('ultimo_evento', 'respondeu_email', 'paginas_visitadas', 5),
     '2026-01-20 10:15:00.000000'),
    (2, 1, 2, 63, 1, 'score-v1', '2026-01-20 11:30:00.000000', 2, 15000.00, 'qualificado', 70, 61, 58, 65,
     JSON_OBJECT('ultimo_evento', 'visitou_site', 'paginas_visitadas', 3),
     '2026-01-20 11:30:00.000000'),
    (3, 1, 3, 38, 1, 'score-v1', '2026-01-20 13:45:00.000000', 2, 42000.00, 'novo', 45, 32, 40, 35,
     JSON_OBJECT('ultimo_evento', 'origem_linkedin', 'paginas_visitadas', 1),
     '2026-01-20 13:45:00.000000')
ON DUPLICATE KEY UPDATE
    `fk_empresa` = VALUES(`fk_empresa`),
    `fk_possivel_cliente` = VALUES(`fk_possivel_cliente`),
    `score` = VALUES(`score`),
    `fk_versao_configuracao_score` = VALUES(`fk_versao_configuracao_score`),
    `score_versao` = VALUES(`score_versao`),
    `calculado_em` = VALUES(`calculado_em`),
    `fk_usuario_responsavel` = VALUES(`fk_usuario_responsavel`),
    `valor_potencial` = VALUES(`valor_potencial`),
    `status_comercial` = VALUES(`status_comercial`),
    `fit_base` = VALUES(`fit_base`),
    `engajamento` = VALUES(`engajamento`),
    `comportamento` = VALUES(`comportamento`),
    `nota_origem` = VALUES(`nota_origem`),
    `sinais` = VALUES(`sinais`),
    `atualizado_em` = VALUES(`atualizado_em`);

INSERT INTO `classificacao_match`
    (`id_classificacao_match`, `fk_match`, `classificacao`, `atualizado_em`)
VALUES
    (1, 1, 'aprovado', '2026-01-20 10:20:00.000000'),
    (2, 2, 'bom', '2026-01-20 11:35:00.000000'),
    (3, 3, 'ruim', '2026-01-20 13:50:00.000000')
ON DUPLICATE KEY UPDATE
    `fk_match` = VALUES(`fk_match`),
    `classificacao` = VALUES(`classificacao`),
    `atualizado_em` = VALUES(`atualizado_em`);

-- ============================================================
-- 9. DETALHE DA CONFIGURACAO DE SCORE
-- ============================================================
INSERT INTO `configuracao_score_detalhe`
    (`fk_versao_configuracao_score`, `limite_otimo`, `limite_bom`,
     `icp_segmentos`, `icp_portes`, `icp_orcamento_min`, `valores`)
VALUES
    (1, 80, 60,
     JSON_ARRAY('Tecnologia', 'Servicos contabeis', 'Comercio varejista'),
     JSON_ARRAY('pequeno', 'medio'), 10000.00,
     JSON_OBJECT('limite_ruim', 0, 'limite_bom', 60, 'limite_otimo', 80,
                 'pesos', JSON_OBJECT('fit', 35, 'engajamento', 25,
                                      'comportamento', 25, 'origem', 15)))
ON DUPLICATE KEY UPDATE
    `limite_otimo` = VALUES(`limite_otimo`),
    `limite_bom` = VALUES(`limite_bom`),
    `icp_segmentos` = VALUES(`icp_segmentos`),
    `icp_portes` = VALUES(`icp_portes`),
    `icp_orcamento_min` = VALUES(`icp_orcamento_min`),
    `valores` = VALUES(`valores`);

-- ============================================================
-- 10. ATIVIDADES DOS LEADS
-- ============================================================
INSERT INTO `atividade_lead`
    (`id_atividade`, `fk_match`, `fk_usuario`, `tipo`, `descricao`, `ocorrido_em`)
VALUES
    (1, 1, 1, 'email', 'Enviou proposta comercial por email', '2026-01-18 09:10:00.000000'),
    (2, 1, 1, 'site', 'Visitou a pagina de precos', '2026-01-19 14:25:00.000000'),
    (3, 2, 2, 'site', 'Visitou a pagina de integracoes', '2026-01-19 16:40:00.000000'),
    (4, 3, 2, 'origem', 'Lead capturado via LinkedIn', '2026-01-20 13:45:00.000000')
ON DUPLICATE KEY UPDATE
    `fk_match` = VALUES(`fk_match`),
    `fk_usuario` = VALUES(`fk_usuario`),
    `tipo` = VALUES(`tipo`),
    `descricao` = VALUES(`descricao`),
    `ocorrido_em` = VALUES(`ocorrido_em`);

COMMIT;

-- ============================================================
-- FIM DA MASSA
-- ============================================================
