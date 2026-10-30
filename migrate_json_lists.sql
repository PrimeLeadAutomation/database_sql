-- Corrige os registros da massa antiga sem alterar dados criados pela aplicacao.
START TRANSACTION;

UPDATE `match_empresa_lead`
SET `sinais` = CASE `id_match`
    WHEN 1 THEN JSON_ARRAY('Respondeu e-mail', 'Visitou 5 paginas')
    WHEN 2 THEN JSON_ARRAY('Visitou o site', 'Visitou 3 paginas')
    WHEN 3 THEN JSON_ARRAY('Origem LinkedIn', 'Visitou 1 pagina')
    ELSE `sinais`
END
WHERE `id_match` IN (1, 2, 3)
  AND JSON_TYPE(`sinais`) = 'OBJECT';

UPDATE `configuracao_score_detalhe`
SET `valores` = JSON_ARRAY('Inovacao', 'Decisao agil', 'Visao de longo prazo')
WHERE `fk_versao_configuracao_score` = 1
  AND JSON_TYPE(`valores`) = 'OBJECT';

COMMIT;
