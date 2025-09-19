BEGIN;

--   Main categories ----------------------------------------------------------
INSERT INTO occurrence_category (category_name)
VALUES
('Emergência médica'),
('Incêndio'),
('Acidente de trânsito'),
('Outros');

--   Subcategories ------------------------------------------------------------
INSERT INTO occurrence_category (category_name, parent_category_id)
VALUES
('Parada cardíaca', GET_CATEGORY_ID_BY_NAME('Emergência médica')),
('Convulsão', GET_CATEGORY_ID_BY_NAME('Emergência médica')),
('Ferimento grave', GET_CATEGORY_ID_BY_NAME('Emergência médica')),
('Intoxicação', GET_CATEGORY_ID_BY_NAME('Emergência médica'));

INSERT INTO occurrence_category (category_name, parent_category_id)
VALUES
('Residencial', GET_CATEGORY_ID_BY_NAME('Incêndio')),
('Comercial', GET_CATEGORY_ID_BY_NAME('Incêndio')),
('Vegetação', GET_CATEGORY_ID_BY_NAME('Incêndio')),
('Veículo', GET_CATEGORY_ID_BY_NAME('Incêndio'));

INSERT INTO occurrence_category (category_name, parent_category_id)
VALUES
('Colisão', GET_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Atropelamento', GET_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Capotamento', GET_CATEGORY_ID_BY_NAME('Acidente de trânsito')),
('Queda de motocicleta', GET_CATEGORY_ID_BY_NAME('Acidente de trânsito'));

INSERT INTO occurrence_category (category_name, parent_category_id)
VALUES
('Queda de árvore', GET_CATEGORY_ID_BY_NAME('Outros')),
('Alagamento', GET_CATEGORY_ID_BY_NAME('Outros')),
('Animal Derido', GET_CATEGORY_ID_BY_NAME('Outros'));

COMMIT;
