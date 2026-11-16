-- Da eseguire una volta, fuori dallo script:
-- CREATE DATABASE gestionale_personale;

CREATE TABLE utente (
  email    VARCHAR(255) PRIMARY KEY,
  password VARCHAR(255) NOT NULL
);

CREATE TABLE lezione (
  id           SERIAL PRIMARY KEY,
  corso        VARCHAR(255) NOT NULL,
  giorno       VARCHAR(255) NOT NULL,
  ora_inizio   TIME NOT NULL,
  ora_fine     TIME NOT NULL,
  data_fine    DATE,
  date_no      DATE[],
  aula         VARCHAR(255) NOT NULL,
  email_utente VARCHAR(255) NOT NULL REFERENCES utente(email)
);

CREATE TABLE impegno(
  ID SERIAL PRIMARY KEY,
  titolo VARCHAR(255) NOT NULL,
  data DATE NOT NULL,
  ora_inizio TIME,
  ora_fine TIME,
  luogo VARCHAR(255),
  email_utente VARCHAR(255) NOT NULL REFERENCES utente(email),
);

CREATE TABLE progetto(
  
)
