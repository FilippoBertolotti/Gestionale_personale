# Gestionale Personale

Applicazione web personale che riunisce in un unico posto impegni, orario universitario, tempo libero, progetti e spese.

> **Stato del progetto:** in sviluppo. Al momento è pronto solo lo scheletro del backend. Le istruzioni d'uso verranno aggiunte più avanti.

## Descrizione

Il Gestionale Personale mostra la giornata in modo chiaro e aiuta a usare bene il tempo che resta. Legge gli impegni dal calendario, importa le lezioni universitarie da un file, calcola le fasce di tempo libero e propone cosa fare. Tiene inoltre traccia delle spese personali.

## Funzionalità

### Impegni da Google Calendar
- Accesso a Google Calendar tramite API, in sola lettura.
- Visualizzazione di allenamenti, partite e altri impegni presenti nel calendario.

### Orario universitario
- Caricamento delle lezioni da file **CSV** o **XLS/XLSX**.
- Gestione dei giorni in cui le lezioni non vengono svolte (festività, sospensioni).
- Formattazione e normalizzazione dei dati tramite l'API di **Gemini**, con anteprima e conferma prima del salvataggio.

### Tempo libero e attività proposte
- Calcolo delle fasce libere sottraendo da ogni giornata lezioni e impegni del calendario.
- Proposta di attività da svolgere, scelte tra alcune preimpostate.
- Tra le proposte compaiono lo **studio** e l'**avanzamento dei progetti in corso** inseriti dall'utente.

### Progetti in corso
- Inserimento e gestione dei progetti su cui si sta lavorando (priorità, scadenza, percentuale completamento).

### Gestione dei costi personali
- Registrazione di entrate e uscite, divise per categoria.
- Riepilogo mensile con totali e saldo.

## Tecnologie

| Parte | Tecnologia |
|---|---|
| Backend | Python 3.12+, FastAPI, Uvicorn |
| Database | SQLite (con SQLAlchemy), migrabile a PostgreSQL |
| Validazione dati | Pydantic |
| Test | pytest |
| Integrazioni | Google Calendar API (OAuth), Gemini API |
| Frontend | React (previsto) |

## Struttura del progetto

```text
gestionale_personale/
├── backend/      API e logica (Python, FastAPI)
└── frontend/     interfaccia web (React, in arrivo)
```

## Prossimi passi

- [x] Backend minimo con endpoint di controllo
- [ ] Test automatici e struttura a livelli
- [ ] Database e gestione delle spese
- [ ] Progetti in corso
- [ ] Importazione dell'orario universitario con Gemini
- [ ] Integrazione con Google Calendar
- [ ] Calcolo del tempo libero e attività proposte
- [ ] Frontend React

## Istruzioni d'uso

Da completare.
