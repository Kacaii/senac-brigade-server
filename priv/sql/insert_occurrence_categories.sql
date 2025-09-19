BEGIN;

--   Main categories
INSERT INTO occurrence_category (category_name)
VALUES
('Emergência médica'),
('Incêndio'),
('Acidente de trânsito'),
('Outros');

COMMIT;
