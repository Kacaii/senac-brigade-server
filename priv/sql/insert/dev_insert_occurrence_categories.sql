BEGIN;

--   Main categories --------------------------------------------------------
INSERT INTO public.occurrence_category (category_name)
VALUES
('Emergência médica'),
('Incêndio'),
('Acidente de trânsito'),
('Outros');

--   Subcategories ------------------------------------------------------------
INSERT INTO public.occurrence_category (category_name, parent_category_id)
VALUES
('Parada cardíaca', QUERY_CATEGORY_ID_BY_NAME('Emergência médica')),
('Convulsão', QUERY_CATEGORY_ID_BY_NAME('Emergência médica')),
('Ferimento grave', QUERY_CATEGORY_ID_BY_NAME('Emergência médica')),
('Intoxicação', QUERY_CATEGORY_ID_BY_NAME('Emergência médica'));

INSERT INTO public.occurrence_category (category_name, parent_category_id)
VALUES
('Residencial', QUERY_CATEGORY_ID_BY_NAME('Incêndio')),
('Comercial', QUERY_CATEGORY_ID_BY_NAME('Incêndio')),
('Vegetação', QUERY_CATEGORY_ID_BY_NAME('Incêndio')),
('Veículo', QUERY_CATEGORY_ID_BY_NAME('Incêndio'));

INSERT INTO public.occurrence_category (category_name, parent_category_id)
VALUES
('Colisão', QUERY_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Atropelamento', QUERY_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Capotamento', QUERY_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Queda de motocicleta', QUERY_CATEGORY_ID_BY_NAME('Acidente de trânsito'));

INSERT INTO public.occurrence_category (category_name, parent_category_id)
VALUES
('Queda de árvore', QUERY_CATEGORY_ID_BY_NAME('Outros')),
('Alagamento', QUERY_CATEGORY_ID_BY_NAME('Outros')),
('Animal Ferido', QUERY_CATEGORY_ID_BY_NAME('Outros'));

COMMIT;
