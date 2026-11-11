# Guida: Gestionale Personale — programma base

Guida passo passo (Parti 1–3) dal primo file vuoto alla prima funzionalità completa.

---

# Prima di iniziare

## Come usare questa guida

Questa guida ti accompagna dal **primo file vuoto** fino a un'applicazione web completa: un gestionale personale che legge i tuoi impegni da Google Calendar, importa l'orario universitario da un file CSV o Excel (con l'aiuto di Gemini), calcola il tempo libero, propone cosa fare e tiene traccia delle spese.

Sai già programmare (C++, Java, JavaScript, PHP, un po' di TypeScript), quindi non ti spiego che cos'è una variabile. Ti spiego invece le cose che cambiano da un progetto all'altro: come è organizzato un backend moderno in Python, a cosa serve ogni file, perché lo creiamo e che cosa significa ogni riga importante.

Ogni passo ha la stessa struttura, così sai sempre dove guardare:

- **Cosa facciamo**: l'azione concreta (creare un file, lanciare un comando).
- **Il codice o il comando**: da copiare così com'è.
- **Perché**: il motivo per cui quel pezzo esiste.
- **Significato**: che cosa vuol dire, riga per riga o a blocchi.
- **Verifica**: come controllare che sia andato tutto bene prima di proseguire.
- **Se qualcosa va storto**: gli errori più probabili e come risolverli.

> **💡 Perché**
>
> Riquadro blu: il motivo di una scelta. Se capisci il perché, domani saprai prendere da solo decisioni simili.


> **📖 Significato**
>
> Riquadro viola: la spiegazione di che cosa fa il codice, a blocchi o riga per riga.


> **⚠️ Attenzione**
>
> Riquadro giallo: un dettaglio facile da sbagliare o una cosa da non fare mai.


> **🔧 Se qualcosa va storto**
>
> Riquadro rosso: gli errori che si incontrano più spesso a quel punto e come uscirne.


> **✅ Verifica**
>
> Riquadro verde: come controllare che il passo sia riuscito. **Non andare avanti se la verifica non passa.**


> **📝 Consiglio**
>
> Riquadro grigio: un'abitudine utile o un'alternativa.


### La regola d'oro

**Un passo alla volta, e verifica ogni volta.** Il modo più rapido per perdere un pomeriggio è scrivere cinque file di fila e scoprire poi che il primo conteneva un refuso. Dopo ogni passo c'è un controllo: fallo.

### Come leggere un errore

Quando un comando fallisce, il terminale scrive molte righe. Non spaventarti: l'informazione utile è quasi sempre **nelle ultime righe**. In Python, l'ultima riga di un errore dice il tipo di problema e il motivo (per esempio `ModuleNotFoundError: No module named 'app'`). Le righe sopra (il "traceback") dicono in quali file e a quale riga è successo. Impara a leggere prima l'ultima riga, poi risali.

Nell'Appendice A trovi una tabella con gli errori più comuni di questo progetto, comprese le due trappole in cui è inciampato chi ha seguito questi passi per primo: un nome di progetto con lo spazio e un refuso nella parola `dependencies`.


## La mappa: com'è fatta l'applicazione

Immagina un ristorante.

- Il **frontend** è la **sala**: quello che vedi nel browser (pulsanti, tabelle, il calendario). Non sa cucinare: sa solo prendere ordinazioni e mostrare i piatti.
- Il **backend** è la **cucina**: riceve le richieste ("dammi gli impegni di oggi"), fa il lavoro vero (parla con Google, calcola il tempo libero) e restituisce il risultato.
- Il **database** è la **dispensa**: conserva ciò che deve restare nel tempo (orario, progetti, spese).
- Le **API esterne** (Google Calendar, Gemini) sono i **fornitori**: il backend li chiama quando gli serve un ingrediente.

```text
 Browser (React)                Backend (FastAPI, Python)              Database
 +-----------------+   HTTP    +-----------------------------+  SQL   +----------+
 |  pagine, form,  | --------> |  endpoint -> servizi -> dati| -----> |  SQLite  |
 |  tabelle        | <-------- |                             | <----- |  (file)  |
 +-----------------+   JSON    +--------------+--------------+        +----------+
                                              |
                                              +--> Google Calendar (API)
                                              +--> Gemini (API)
```

**HTTP** è il "linguaggio" con cui il browser parla al backend. Una richiesta ha un **metodo** (GET per leggere, POST per creare, PUT per sostituire, PATCH per modificare in parte, DELETE per cancellare) e un **indirizzo** (per esempio `/api/v1/expenses`). La risposta contiene un **codice di stato** (200 = ok, 201 = creato, 204 = ok senza contenuto, 400/422 = richiesta sbagliata, 401 = non autorizzato, 404 = non trovato, 500 = errore del server) e di solito dei dati in formato **JSON**, che è semplicemente testo strutturato come un oggetto JavaScript.

### Il percorso di una richiesta

Quando nella pagina "Oggi" scegli una data, succede questo:

1. Il browser invia `GET /api/v1/planner/day?day=2026-10-08`.
2. FastAPI trova l'**endpoint** che gestisce quell'indirizzo e controlla che i dati in ingresso siano validi.
3. L'endpoint chiede ai **servizi** di fare il lavoro: leggere le lezioni dal database, chiedere gli eventi a Google Calendar, calcolare il tempo libero, scegliere le attività.
4. Il risultato torna all'endpoint, che lo trasforma in JSON e lo spedisce al browser.
5. React riceve il JSON e disegna la pagina.

### I livelli del backend

Il codice del backend è diviso in cartelle, ognuna con **una sola responsabilità**:

| Cartella | Che cosa contiene | Regola |
|---|---|---|
| `app/api` | Gli **endpoint**: ricevono la richiesta HTTP e rispondono | Devono essere sottili: niente calcoli, solo "smisto e restituisco" |
| `app/services` | La **logica**: calcoli, regole, chiamate a Google e Gemini | Non sanno nulla di HTTP; si possono testare da soli |
| `app/models` | Le **tabelle** del database (classi SQLAlchemy) | Descrivono come sono salvati i dati |
| `app/schemas` | La **forma dei dati** in ingresso e uscita (classi Pydantic) | Validano e documentano i dati che passano dall'API |
| `app/core` | Impostazioni e collegamento al database | Cose usate da tutti |
| `tests` | I **test automatici** | Verificano che tutto funzioni, ogni volta che vuoi |

> **💡 Perché dividere così**
>
> Se ogni cosa stesse in un unico file, dopo dieci funzionalità sarebbe impossibile orientarsi e modificare una parte romperebbe le altre. Con i livelli sai sempre dove andare a mettere le mani: una regola di calcolo? In `services`. Una nuova tabella? In `models`. Un nuovo indirizzo web? In `api`. E soprattutto: la logica importante (per esempio il calcolo del tempo libero) non dipende dal web né dal database, quindi la testi in un millesimo di secondo con dati finti.


## Che cosa ti serve

| Strumento | A che cosa serve | Quando |
|---|---|---|
| **Python 3.12 o più recente** (tu hai la 3.13.1) | Il linguaggio del backend | Da subito |
| **Visual Studio Code** | L'editor in cui scrivi e da cui lanci i comandi | Da subito |
| **Git** | Salva la storia delle modifiche | Passo 10 |
| **Un account Google** | Google Calendar e la console Google Cloud | Parte 6 |
| **Una chiave API di Gemini** | Per far leggere l'orario a Gemini | Parte 5 |
| **Node.js (versione LTS)** | Per costruire il frontend React | Parte 8 |
| **Un browser** (Chrome, Edge, Firefox) | Per provare l'app | Sempre |

## Che cosa costruiremo, in che ordine

| Parte | Che cosa si ottiene |
|---|---|
| 1. Il backend minimo | Un server che risponde "ok" a una richiesta: la base di tutto |
| 2. Test e struttura a livelli | Il primo test automatico e le cartelle ordinate |
| 3. Database e spese | Salvare dati veri; prima funzionalità completa (la pagina costi) |
| 4. Progetti e materie | Ripeti lo schema già imparato: i "progetti in corso" |
| 5. Orario universitario | Carichi un CSV/Excel, Gemini lo normalizza, tu confermi |
| 6. Google Calendar | Accesso ai tuoi eventi con login Google (OAuth) |
| 7. Tempo libero e attività | Il cuore: calcolo delle fasce libere e proposte intelligenti |
| 8. Il frontend React | Le quattro pagine nel browser |
| 9. La parte agentica | Come far spiegare e ripianificare un assistente, in sicurezza |
| 10. Rifinire | Migrazioni, Postgres, Docker, sicurezza, idee future |

> **📝 Ritmo consigliato**
>
> Una parte per volta. Le Parti 1 e 2 si fanno in una serata. La Parte 3 è la più importante da capire bene, perché le Parti 4, 5, 6 e 7 ripetono lo stesso schema (modello, schema, servizio, endpoint, test) su altri dati.



---

# Parte 1 · Il backend minimo

In questa parte costruisci l'ossatura: la cartella del progetto, l'ambiente Python isolato, e un server che risponde a una richiesta. Alla fine vedrai il tuo primo endpoint funzionare nel browser.

## Passo 1 · Creare la cartella del progetto

**Cosa facciamo.** Creiamo la cartella principale e, dentro, la sottocartella `backend`. Poi apriamo la cartella principale in Visual Studio Code.

1. In Esplora file crea la cartella `C:\progetti\gestionale_personale`.
2. Dentro di essa crea una cartella `backend`.
3. Apri Visual Studio Code, scegli **File, Apri cartella** e seleziona `gestionale_personale` (quella principale, non `backend`).

**`Struttura iniziale`**

```text
gestionale_personale/
└── backend/
```

> **💡 Perché la cartella principale e perché "backend" dentro**
>
> La cartella principale conterrà due progetti fratelli: `backend` (Python) e, più avanti, `frontend` (React). Tenerli separati permette di avviarli, testarli e pubblicarli indipendentemente, mentre Git (Passo 10) salverà la storia di entrambi insieme.
>
> Il nome senza spazi non è un capriccio: molti strumenti da riga di comando si confondono con gli spazi nei percorsi. Usa lettere minuscole, numeri, trattini o underscore.


> **✅ Verifica**
>
> In VS Code, nella barra laterale a sinistra, vedi `GESTIONALE_PERSONALE` con dentro la cartella `backend`.


> **🔧 Se qualcosa va storto**
>
> La cartella si chiama "gestionale personale" con lo spazio? Chiudi VS Code, rinominala (`gestionale_personale`) e riaprila. È molto più semplice farlo adesso che dopo.


## Passo 2 · Aprire il terminale in VS Code

**Cosa facciamo.** Apriamo il terminale dentro VS Code: menu **Terminale, Nuovo terminale**. Si apre un pannello in basso, già posizionato nella cartella principale del progetto.

Sul terminale c'è una cosa da sapere subito, perché è la fonte di confusione numero uno su Windows. Esistono due "shell":

| Shell | Come la riconosci | Note |
|---|---|---|
| **PowerShell** | La riga inizia con `PS C:\progetti\...>` | Più moderna. È quella che ti consiglio |
| **Prompt dei comandi (cmd)** | La riga inizia con `C:\progetti\...>` (senza `PS`) | Più vecchia. Alcuni comandi cambiano |

Per scegliere la shell: nel pannello del terminale clicca la **freccia accanto al simbolo +**, poi **Seleziona profilo predefinito** e scegli **PowerShell**. Apri un nuovo terminale per applicare la scelta.

Poi spostati nella cartella `backend`:

**`Terminale`**

```text
cd backend
```

> **📖 Che cosa fa `cd`**
>
> `cd` sta per *change directory* ("cambia cartella"): sposta il terminale dentro la cartella indicata. Tutti i comandi successivi lavorano lì. Il percorso davanti al cursore ti dice sempre dove sei. Puoi anche scrivere solo le prime lettere e premere **Tab**: il terminale completa il nome da solo.


> **⚠️ Attenzione**
>
> Quasi tutti i comandi della Parte 1 e delle Parti 2-7 vanno lanciati **dentro `backend`**. Se compare un errore strano subito dopo aver lanciato un comando, controlla per prima cosa di essere nella cartella giusta.


> **✅ Verifica**
>
> La riga del terminale finisce con `...\gestionale_personale\backend>`.


## Passo 3 · Controllare la versione di Python

**Cosa facciamo.** Verifichiamo che Python sia installato e abbastanza recente.

**`Terminale`**

```text
python --version
```

Deve rispondere con `Python 3.12` o più recente (per esempio `Python 3.13.1`).

> **📖 Perché il progetto richiede almeno la 3.12**
>
> Nel file `pyproject.toml` scriveremo `requires-python = ">=3.12"`. Il codice usa funzioni recenti del linguaggio (per esempio `str | None` per dire "testo oppure niente"). Con una versione più vecchia l'installazione si fermerebbe subito con un messaggio chiaro, invece di rompersi più avanti.


> **🔧 Se qualcosa va storto**
>
> - **`python3` non funziona su Windows.** Se provi `python3 --version` ottieni "Python non è stato trovato; eseguire senza argomenti per installare dal Microsoft Store". È normale: su Windows il comando giusto è `python` (oppure `py`). In tutta la guida useremo `python`.
> - **Python non è installato** o `python --version` dà errore: scaricalo da python.org, avvia l'installer e **spunta "Add python.exe to PATH"** prima di cliccare Install. Poi chiudi e riapri VS Code.
> - **La versione è troppo vecchia** (3.10, 3.11): installa la 3.13 dallo stesso sito.


## Passo 4 · Creare e attivare l'ambiente virtuale

**Cosa facciamo.** Creiamo una "scatola" isolata per le librerie di questo progetto e la attiviamo.

**`Terminale (dentro backend)`**

```text
python -m venv .venv
```

Poi attivala. Il comando dipende dalla shell:

**`PowerShell`**

```text
.venv\Scripts\Activate.ps1
```

**`Prompt dei comandi (cmd)`**

```text
.venv\Scripts\activate
```

> **💡 Perché un ambiente virtuale**
>
> Ogni progetto Python ha bisogno di librerie diverse, spesso in versioni diverse. Se le installassi tutte nel Python di sistema, prima o poi due progetti entrerebbero in conflitto. L'ambiente virtuale è una cartella (`.venv`) con una copia isolata di Python e di `pip`: le librerie di questo progetto vivono solo lì. Se qualcosa si rompe, cancelli `.venv` e la ricrei in un minuto, senza toccare il resto del computer. Non è codice tuo e non va mai caricata su Git: si può sempre rigenerare.


> **📖 Che cosa significa "attivare"**
>
> Creare l'ambiente non basta: va **attivato**. L'attivazione esegue un piccolo script che dice al terminale "d'ora in poi, quando scrivo `python` o `pip`, usa quelli dentro `.venv`". Vale solo per quella finestra di terminale: se ne apri un'altra, o chiudi VS Code, va rifatta.


> **✅ Verifica**
>
> Davanti alla riga del terminale compare **`(.venv)`**, per esempio `(.venv) PS C:\progetti\gestionale_personale\backend>`. Finché lo vedi, stai lavorando dentro l'ambiente del progetto.


> **🔧 Se qualcosa va storto**
>
> - **Nessun errore ma `(.venv)` non compare.** Probabilmente hai usato il comando della shell sbagliata. `Activate.ps1` funziona solo in PowerShell, `activate` solo in cmd. Guarda se la tua riga inizia con `PS`.
> - **PowerShell dice che l'esecuzione di script è disabilitata** ("running scripts is disabled on this system"). È una protezione di Windows, non un tuo errore. Esegui una volta sola: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` e conferma con `S` (o `Y`). Poi ripeti l'attivazione. Il comando consente gli script scritti sul tuo computer e vale solo per il tuo utente.
> - **VS Code ti chiede** "È stato rilevato un nuovo ambiente virtuale, vuoi usarlo?": rispondi **Sì**. Così l'editor riconosce le librerie installate.


> **📝 Attivazione automatica**
>
> In VS Code premi **Ctrl+Shift+P**, scrivi `Python: Select Interpreter` e scegli quello dentro `.venv`. Da quel momento i nuovi terminali attivano l'ambiente da soli.


## Passo 5 · Il file pyproject.toml

**Cosa facciamo.** Creiamo il file che descrive il progetto: nome, versione di Python richiesta e librerie necessarie.

Crea `backend/pyproject.toml`:

**`backend/pyproject.toml`**

```toml
[project]
name = "gestionale-personale"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
include = ["app*"]
```

> **💡 Perché per primo**
>
> Tutto il resto del codice userà librerie esterne. Se le elenchi qui, chiunque (tu su un altro computer tra sei mesi) ricrea lo stesso ambiente con un solo comando, senza ricordare che cosa avevi installato a mano. È l'equivalente del `package.json` di Node o del `pom.xml` di Maven.


> **📖 Sezione per sezione**
>
> - `[project]` sono i dati del progetto. `name` è un'etichetta, `version` il numero di versione.
> - `requires-python = ">=3.12"`: versione minima di Python.
> - `dependencies`: le librerie. **FastAPI** è il framework con cui scriviamo gli endpoint. **Uvicorn** è il server che tiene acceso FastAPI e ascolta le richieste (FastAPI da solo è solo codice; Uvicorn lo fa girare davvero). `>=0.115` significa "questa versione o più recente". `[standard]` installa anche alcuni extra utili, come il riavvio automatico quando salvi un file.
> - `[build-system]`: dice a `pip` quale strumento usare per installare il progetto (setuptools). Non devi modificarlo.
> - `[tool.setuptools.packages.find]` con `include = ["app*"]`: dice a setuptools dove trovare il tuo codice, cioè in ogni cartella che inizia con `app`. Senza questa riga, setuptools si confonde appena nella cartella compare una seconda cartella (come `tests`) e rifiuta di installare.


> **⚠️ Due errori già incontrati da chi ha fatto questi passi**
>
> 1. **Il nome non può contenere spazi.** Con `name = "gestionale personale"` pip risponde `project.name must be pep508-identifier`. Il nome del progetto segue uno standard (PEP 508): ammette solo lettere, numeri, trattini, underscore e punti. Non deve coincidere col nome della cartella.
> 2. **Un refuso nel nome di una chiave blocca tutto.** Con `dependecies` (la "c" e la "e" scambiate) pip risponde `project must not contain {'dependecies'} properties`. Non ignora la chiave sconosciuta: si ferma, perché potrebbe essere proprio un errore di battitura. Copia e incolla i nomi delle chiavi invece di digitarli.


Nel corso della guida aggiungeremo altre librerie a `dependencies`, una parte per volta, ogni volta con un motivo preciso.

## Passo 6 · Il pacchetto app

**Cosa facciamo.** Dentro `backend` crea la cartella `app` e, dentro `app`, un file vuoto chiamato esattamente `__init__.py` (due underscore prima e dopo). **Lascialo vuoto.**

**`Struttura`**

```text
backend/
├── pyproject.toml
└── app/
    └── __init__.py      (vuoto)
```

> **💡 Perché serve**
>
> Per Python una cartella è solo una cartella finché non contiene un file `__init__.py`: con quel file diventa un **pacchetto**, cioè un insieme di moduli che puoi importare (`from app.main import app`). Inoltre setuptools, con la riga `include = ["app*"]` di prima, riconosce `app` come pacchetto proprio grazie a quel file. Senza, non troverebbe nulla da installare.


> **📖 Il nome**
>
> `__init__` viene da *initialize*: Python lo esegue la prima volta che qualcuno importa il pacchetto. Per ora è vuoto perché non c'è nulla da inizializzare. La cartella si chiama `app` per convenzione nei progetti FastAPI: dentro c'è il programma, fuori (in `backend`) il contorno (configurazione, test).


## Passo 7 · Il primo endpoint (main.py)

**Cosa facciamo.** Scriviamo il primo vero codice: un'applicazione FastAPI con un solo endpoint che risponde "ok".

Crea `backend/app/main.py`:

**`backend/app/main.py`**

```python
from fastapi import FastAPI

app = FastAPI(title="Gestionale Personale")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

> **💡 Perché così piccolo**
>
> Per avere subito qualcosa che funziona e che puoi vedere. Costruire un pezzo alla volta e verificarlo è più sicuro che scrivere tutto e scoprire dopo che non parte nulla.


> **📖 Riga per riga**
>
> - `from fastapi import FastAPI`: importa la classe `FastAPI` dalla libreria (quella messa in `pyproject.toml`).
> - `app = FastAPI(title=...)`: crea l'applicazione e la salva nella variabile `app`. Il `title` compare nella documentazione automatica. Il nome `app` conta: tra poco dirai a Uvicorn di avviare "l'oggetto `app` che sta in `main`".
> - `@app.get("/health")`: è un **decoratore**, una riga sopra una funzione che le assegna un ruolo. Significa: "quando arriva una richiesta **GET** all'indirizzo `/health`, esegui la funzione qui sotto". GET è il metodo per *leggere* dati (lo stesso che usa il browser quando apri una pagina).
> - `def health() -> dict[str, str]:` la funzione che gestisce la richiesta. `-> dict[str, str]` dichiara che restituisce un dizionario di testi. Python non lo impone, ma FastAPI lo usa per documentare e controllare la risposta, e l'editor ti aiuta meglio.
> - `return {"status": "ok"}`: FastAPI converte il dizionario in **JSON** (`{"status": "ok"}`) e lo spedisce. È un endpoint "di salute": non fa nulla se non rispondere "sono acceso", e serve a te, ai test e in futuro a strumenti come Docker.


> **✅ Struttura a questo punto**
>
> `backend/pyproject.toml`, `backend/app/__init__.py`, `backend/app/main.py`.


## Passo 8 · Installare le librerie

**Cosa facciamo.** Con l'ambiente attivo (`(.venv)` visibile) e dentro `backend`:

**`Terminale (dentro backend, con .venv attivo)`**

```text
pip install -e .
```

> **📖 Pezzo per pezzo**
>
> - `pip` è il gestore di pacchetti di Python: scarica le librerie dal sito PyPI. Grazie all'attivazione, usa quello dentro `.venv`.
> - `install` è l'operazione richiesta.
> - `.` (il punto) significa "la cartella in cui sono ora": installa il progetto che trovi qui. Pip legge `pyproject.toml`, vede `dependencies` e scarica FastAPI, Uvicorn e tutto ciò che a loro volta richiedono (Starlette, Pydantic...).
> - `-e` sta per *editable*: invece di copiare il tuo codice nell'ambiente, pip crea un collegamento alla cartella `app`. Quando modifichi un file, la modifica vale subito, senza reinstallare.


> **✅ Verifica**
>
> Dopo un minuto circa compare una riga come `Successfully installed ... fastapi-0.1xx ... uvicorn-0.xx ... gestionale-personale-0.1.0`. Che siano installati molti più pacchetti dei due che hai scritto è normale. Un avviso su una nuova versione di pip si può ignorare.


> **🔧 Se qualcosa va storto**
>
> - `project.name must be pep508-identifier` oppure `project must not contain {'...'} properties`: vedi i due errori del Passo 5.
> - `No module named pip` o comando non trovato: l'ambiente non è attivo (Passo 4).
> - Errore di rete o certificati: controlla la connessione e riprova.


## Passo 9 · Avviare il server e provarlo

**Cosa facciamo.** Accendiamo il backend.

**`Terminale (dentro backend, con .venv attivo)`**

```text
uvicorn app.main:app --reload
```

> **📖 Che cosa vuol dire**
>
> - `uvicorn` è il server installato prima.
> - `app.main:app` si legge: file `app/main.py` (senza `.py`), poi due punti, poi il nome dell'oggetto dentro quel file, cioè la variabile `app`.
> - `--reload` riavvia il server da solo ogni volta che salvi un file. Comodissimo mentre sviluppi (in produzione non si usa).


Il terminale **non torna al prompt**: resta occupato perché il server è in esecuzione e aspetta richieste. Dovresti leggere:

**`Output atteso`**

```text
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

`127.0.0.1` (detto anche *localhost*) è il tuo stesso computer e `8000` è la **porta**, la "porta d'ingresso" a cui bussare. Il server è visibile solo a te.

Ora apri il browser:

1. **http://127.0.0.1:8000/health** mostra `{"status":"ok"}`: è la risposta della tua funzione.
2. **http://127.0.0.1:8000/docs** mostra la **documentazione interattiva** che FastAPI genera da sola. Trovi il tuo `GET /health`; premi **Try it out** poi **Execute** per chiamarlo da lì. Useremo spesso questa pagina per provare gli endpoint.

Nel terminale, a ogni richiesta, compare una riga come `GET /health HTTP/1.1" 200 OK`: è il registro del server.

Per **fermare** il server premi **Ctrl+C** nel terminale. Per lanciare altri comandi mentre il server gira, apri un secondo terminale con il simbolo **+** (ricorda di attivare `.venv` anche lì).

> **🔧 Se qualcosa va storto**
>
> - `uvicorn` non è riconosciuto: l'ambiente non è attivo.
> - `Error loading ASGI app. Could not import module "app.main"`: non sei dentro `backend`, oppure manca `__init__.py` in `app`.
> - `address already in use` / porta 8000 occupata: c'è già un altro server acceso (magari in un terminale dimenticato). Chiudilo, oppure usa un'altra porta con `--port 8001`.
> - Windows chiede se consentire l'accesso alla rete a Python: puoi annullare, in locale funziona lo stesso.


## Passo 10 · Git: salvare la storia del progetto

**Cosa facciamo.** Inizializziamo Git nella cartella **principale** (quella che conterrà backend e frontend) e facciamo il primo salvataggio.

Prima fermati con **Ctrl+C** se il server è acceso, poi:

**`Terminale (nella cartella principale)`**

```text
cd ..
git --version
git init
```

Crea nella cartella principale il file `.gitignore`:

**`.gitignore`**

```
# Python
.venv/
__pycache__/
*.egg-info/
.pytest_cache/

# Segreti e dati locali: MAI su Git
.env
token.json
gestionale.db

# Node
node_modules/
dist/

# Editor e sistema
.vscode/
.idea/
.DS_Store
```

Poi:

**`Terminale`**

```text
git add .
git commit -m "Backend minimo con endpoint health"
```

> **💡 Perché Git**
>
> Git ricorda ogni versione del tuo codice: se rompi qualcosa torni indietro, se vuoi provare un'idea crei un ramo senza rischi. È anche il modo standard di condividere e pubblicare il codice.


> **📖 Che cosa significano i comandi**
>
> - `git init` trasforma la cartella in un repository (crea una cartella nascosta `.git`).
> - `git add .` mette "in preparazione" tutte le modifiche (*staging*).
> - `git commit -m "..."` salva uno **snapshot** con un messaggio che descrive che cosa hai fatto. Fai commit piccoli e frequenti, con messaggi chiari: ne farai uno alla fine di quasi ogni passo importante.
> - Il file `.gitignore` elenca ciò che Git **non deve mai salvare**: `.venv` (si rigenera), `__pycache__` (file temporanei), e soprattutto `.env`, `token.json` e `gestionale.db`, che conterranno chiavi segrete e dati personali.


> **⚠️ Attenzione**
>
> **Non caricare mai chiavi e password su Git.** Se un segreto finisce in un commit, anche cancellandolo dopo resta nella storia: l'unico rimedio è revocare la chiave e crearne una nuova. Il `.gitignore` ti protegge, ma solo se è presente **prima** del primo `git add`.


> **🔧 Se qualcosa va storto**
>
> - `git` non è riconosciuto: installa Git da git-scm.com, poi riapri VS Code.
> - Alla prima volta Git può chiedere chi sei: esegui `git config --global user.name "Il tuo nome"` e `git config --global user.email "la.tua@email"`, poi rifai il commit.
> - Hai fatto `git add` prima di creare il `.gitignore` e `.venv` è finito nello snapshot? Esegui `git rm -r --cached backend/.venv` e rifai il commit.


> **✅ Verifica**
>
> `git log --oneline` mostra il tuo primo commit. `git status` dice "nothing to commit, working tree clean".



---

# Parte 2 · Test e struttura a livelli

Ora che il server risponde, mettiamo due fondamenta importanti prima di aggiungere funzioni: un modo automatico per verificare che tutto funzioni (i test) e la divisione del codice in cartelle con responsabilità precise.

## Passo 11 · Gli strumenti di test

**Cosa facciamo.** Aggiungiamo a `pyproject.toml` un gruppo di librerie "da sviluppatore" e le installiamo.

Apri `backend/pyproject.toml` e inserisci questo blocco **subito dopo** la parentesi `]` che chiude `dependencies` e **prima** di `[build-system]`:

**`backend/pyproject.toml (blocco da aggiungere)`**

```toml
[project.optional-dependencies]
dev = [
    "pytest>=8.3",
    "httpx2>=2.0",
]
```

Poi, con l'ambiente attivo e dentro `backend`:

**`Terminale`**

```text
pip install -e ".[dev]"
```

> **💡 Perché i test**
>
> Finora hai verificato "a occhio", aprendo il browser. Con un endpoint va bene, con trenta no: ogni modifica potrebbe rompere qualcosa senza che te ne accorga. Un **test** è un piccolo programma che fa quella verifica al posto tuo, in una frazione di secondo, ogni volta che vuoi. È anche ciò che ti permette di riorganizzare il codice senza paura: se i test passano ancora, non hai rotto nulla.


> **📖 Che cosa significano le righe**
>
> - `[project.optional-dependencies]` è una sezione per librerie facoltative, raggruppate sotto un nome a scelta. Qui il gruppo si chiama `dev`. Si tengono separate da `dependencies` perché servono solo a chi sviluppa: chi installerà l'app in futuro non deve scaricarle.
> - **pytest** trova ed esegue i test.
> - **httpx2** è la libreria che il `TestClient` di FastAPI usa dietro le quinte per simulare un browser che chiama la tua app **senza avviare un vero server**. Nelle versioni più vecchie di Starlette serviva `httpx`: se lanciando i test compare un errore che dice che manca `httpx`, installa anche quello con `pip install httpx`.
> - `".[dev]"` significa "installa il progetto in questa cartella (`.`) **più** il gruppo `dev`". Le virgolette servono in PowerShell: senza, le parentesi quadre vengono interpretate e il comando fallisce.


> **✅ Verifica**
>
> Compare una riga `Successfully installed ... pytest ... httpx2 ...` (pip installa solo ciò che manca).


## Passo 12 · Il primo test

**Cosa facciamo.** Creiamo la cartella `tests` con il primo test: chiamare `/health` e controllare la risposta.

Dentro `backend` crea la cartella `tests` con un file vuoto `__init__.py` e, accanto, `test_health.py`:

**`backend/tests/test_health.py`**

```python
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

Poi lancia i test:

**`Terminale (dentro backend)`**

```text
pytest
```

> **✅ Verifica**
>
> Compare `1 passed` in verde.


> **📖 Come leggere il test**
>
> - `TestClient(app)` è un finto browser: chiama la tua applicazione direttamente, senza server e senza rete.
> - Una funzione il cui nome inizia con `test_`, dentro un file che inizia con `test_`, viene trovata e lanciata automaticamente da pytest. È una convenzione.
> - `assert` afferma che una condizione è vera. Se è falsa, il test **fallisce** e pytest ti mostra i due valori a confronto.
> - `response.status_code == 200` controlla il codice di stato; `response.json()` legge il corpo come dati Python.


> **📝 Vedi un test fallire (una volta sola)**
>
> Cambia temporaneamente `"ok"` in `"no"` dentro il test e rilancia `pytest`: vedrai il rosso e il confronto tra atteso e ottenuto. Un test che non hai mai visto fallire non ti ha ancora dimostrato di funzionare. Poi rimetti `"ok"`.


> **🔧 Se qualcosa va storto**
>
> - `ModuleNotFoundError: No module named 'app'`: stai lanciando `pytest` fuori da `backend`, oppure non hai installato il progetto con `pip install -e .`.
> - `no tests ran`: controlla i nomi (`test_health.py`, `def test_...`).


## Passo 13 · Organizzare il codice a livelli

**Cosa facciamo.** Creiamo le cartelle in cui andrà il resto del codice, ciascuna con il suo `__init__.py` vuoto.

La struttura che stiamo per ottenere dentro `backend/app`:

**`Struttura`**

```text
app/
├── __init__.py
├── main.py
├── core/            impostazioni e database
├── api/
│   └── v1/
│       └── endpoints/   gli endpoint, un file per argomento
├── models/          le tabelle del database
├── schemas/         la forma dei dati in ingresso e uscita
└── services/        la logica
```

In PowerShell, dentro `backend`, un solo comando le crea tutte (con i file `__init__.py`):

**`PowerShell (dentro backend)`**

```text
"core","api","api\v1","api\v1\endpoints","models","schemas","services" | ForEach-Object { New-Item -ItemType Directory -Force -Path "app\$_" | Out-Null; New-Item -ItemType File -Force -Path "app\$_\__init__.py" | Out-Null }
```

Se preferisci, puoi farlo a mano in VS Code: tasto destro sulla cartella `app`, **Nuova cartella**, poi tasto destro sulla nuova cartella, **Nuovo file**, nome `__init__.py`. In cmd i comandi cambiano: conviene usare l'interfaccia di VS Code.

> **💡 Perché a livelli**
>
> Lo hai visto nella mappa iniziale: ogni cartella ha una responsabilità e **le dipendenze vanno in una sola direzione**. Gli endpoint (`api`) chiamano i servizi (`services`); i servizi usano modelli e schemi; i servizi **non** importano mai nulla da `api`. È questa regola che mantiene il codice ordinato e testabile: puoi provare un servizio senza avviare il web.


> **📖 Perché `v1` nel percorso**
>
> `api/v1` significa "versione 1 dell'API". Tutti gli indirizzi avranno il prefisso `/api/v1/...`. Se un giorno dovrai cambiare il comportamento in modo incompatibile, potrai creare `v2` senza rompere chi usa ancora la `v1`. Per un'app personale è una precauzione piccola ma gratuita.


> **✅ Verifica**
>
> In VS Code vedi le sette cartelle dentro `app`, ciascuna con un `__init__.py`.


## Passo 14 · Spostare /health nel suo router

**Cosa facciamo.** Spostiamo l'endpoint di salute in un file dedicato e colleghiamo tutto tramite un "router".

Crea `backend/app/api/v1/endpoints/health.py`:

**`backend/app/api/v1/endpoints/health.py`**

```python
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

Crea `backend/app/api/v1/router.py`:

**`backend/app/api/v1/router.py`**

```python
from fastapi import APIRouter

from app.api.v1.endpoints import health

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
```

Sostituisci il contenuto di `backend/app/main.py`:

**`backend/app/main.py`**

```python
from fastapi import FastAPI

from app.api.v1.router import api_router

app = FastAPI(title="Gestionale Personale", version="0.1.0")

app.include_router(api_router, prefix="/api/v1")
```

Aggiorna il test (`backend/tests/test_health.py`): l'indirizzo ora è cambiato.

**`backend/tests/test_health.py`**

```python
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

> **📖 Come si incastrano i pezzi**
>
> - Un **`APIRouter`** è un "mini-applicazione" che raccoglie un gruppo di endpoint. Invece di mettere tutti gli endpoint in `main.py`, ne scriviamo uno per argomento (salute, spese, progetti...).
> - `health.py` definisce un router con il suo endpoint, usando `@router.get(...)` al posto di `@app.get(...)`.
> - `router.py` è l'**indice**: raccoglie i router dei vari argomenti in un unico `api_router`. Man mano che aggiungeremo funzioni, aggiungeremo una riga qui.
> - `main.py` diventa cortissimo: crea l'app e vi **monta** il router con il prefisso `/api/v1`. Per questo `/health` ora vive a `/api/v1/health`.
> - `tags=["health"]` serve solo a raggruppare gli endpoint nella pagina `/docs`.


> **✅ Verifica**
>
> `pytest` dà `1 passed`. Se avvii il server (`uvicorn app.main:app --reload`), `http://127.0.0.1:8000/api/v1/health` risponde `{"status":"ok"}` mentre il vecchio `/health` ora dà **404** (non trovato): è giusto, l'abbiamo spostato. Fai un commit: `git add .` e `git commit -m "Struttura a livelli e primo test"` (dalla cartella principale).



---

# Parte 3 · Database e la prima funzionalità: le spese

Qui scrivi la prima funzionalità vera, dall'inizio alla fine: **salvare e leggere le spese**. È la parte più importante da capire, perché le funzioni delle parti successive ripetono lo stesso percorso:

**modello (tabella) → schema (forma dei dati) → servizio (logica) → endpoint (indirizzo web) → test.**

## Passo 15 · Le impostazioni (config.py e .env)

**Cosa facciamo.** Creiamo un unico posto in cui il programma legge le sue impostazioni (percorso del database, chiavi segrete...), senza scriverle nel codice.

Prima aggiungi due librerie a `dependencies` in `pyproject.toml`:

**`backend/pyproject.toml (righe da aggiungere in dependencies)`**

```toml
    "sqlalchemy>=2.0",
    "pydantic-settings>=2.4",
```

e reinstalla: `pip install -e ".[dev]"`.

Crea `backend/app/core/config.py`:

**`backend/app/core/config.py`**

```python
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Cartella "backend": config.py -> core -> app -> backend
BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    # I valori vengono letti dalle variabili d'ambiente o dal file backend/.env
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database: SQLite (un semplice file) finché sviluppi in locale
    database_url: str = f"sqlite:///{(BASE_DIR / 'gestionale.db').as_posix()}"

    # Indirizzi e fuso orario
    cors_origins: str = "http://localhost:5173"
    frontend_url: str = "http://localhost:5173"
    timezone: str = "Europe/Rome"

    # Google Calendar (OAuth)
    google_client_id: str = ""
    google_client_secret: str = ""
    google_redirect_uri: str = "http://localhost:8000/api/v1/auth/google/callback"
    google_token_file: str = str(BASE_DIR / "token.json")

    # Gemini
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.8-flash"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


settings = Settings()
```

Poi crea `backend/.env.example` (il modello da copiare):

**`backend/.env.example`**

```
# Copia questo file in ".env" e compila i valori. Il file ".env" NON va mai su Git.

# Database (SQLite: un semplice file nella cartella backend)
# DATABASE_URL=sqlite:///C:/progetti/gestionale_personale/backend/gestionale.db

# Indirizzi
CORS_ORIGINS=http://localhost:5173
FRONTEND_URL=http://localhost:5173
TIMEZONE=Europe/Rome

# Google Calendar (OAuth) - li ottieni da Google Cloud Console
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost:8000/api/v1/auth/google/callback

# Gemini - la chiave si crea su aistudio.google.com
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.8-flash
```

e copialo in `.env` (il file vero, che resta sul tuo computer):

**`PowerShell (dentro backend)`**

```text
Copy-Item .env.example .env
```

**`cmd (dentro backend)`**

```text
copy .env.example .env
```

> **💡 Perché non scrivere i valori nel codice**
>
> Le chiavi API e i percorsi cambiano da computer a computer e **non devono finire su Git**. Il codice resta uguale per tutti; i valori segreti stanno in `.env`, che il `.gitignore` esclude. Il file `.env.example` invece **va** su Git: dice agli altri (e a te tra sei mesi) quali impostazioni esistono, senza i valori.


> **📖 Il codice, a blocchi**
>
> - `BASE_DIR = Path(__file__).resolve().parents[2]` ricava la cartella `backend` partendo dalla posizione di `config.py` (due livelli sopra: `core`, poi `app`, poi `backend`). Così i percorsi funzionano da qualunque cartella lanci il programma.
> - `class Settings(BaseSettings)`: **pydantic-settings** legge i valori dalle variabili d'ambiente e dal file `.env` e li valida. Il nome del campo in minuscolo (`google_client_id`) corrisponde alla variabile in maiuscolo (`GOOGLE_CLIENT_ID`). Se una variabile manca, vale il valore predefinito scritto nel codice.
> - `database_url`: per ora usiamo **SQLite**, un database contenuto in un solo file (`gestionale.db`), senza nulla da installare. `.as_posix()` scrive il percorso con le barre `/`, che SQLAlchemy accetta anche su Windows. Quando vorrai PostgreSQL basterà cambiare questa riga in `.env`.
> - Le impostazioni di Google e Gemini sono già qui, ma le useremo nelle Parti 5 e 6. Per ora lasciale vuote.
> - `settings = Settings()` crea **un'unica istanza** che il resto del programma importa (`from app.core.config import settings`).


> **⚠️ Attenzione**
>
> Se in `.env` scrivi un valore che contiene spazi o caratteri speciali, mettilo tra virgolette. E ricorda: **mai** committare `.env`.


## Passo 16 · Il database (database.py)

**Cosa facciamo.** Scriviamo il codice che si collega al database e apre una "sessione" per ogni richiesta.

Crea `backend/app/core/database.py`:

**`backend/app/core/database.py`**

```python
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

# SQLite vuole questo parametro perché FastAPI usa più thread
connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}

engine = create_engine(settings.database_url, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    """Classe madre di tutti i modelli (le tabelle)."""


def get_db() -> Generator[Session, None, None]:
    """Apre una sessione per la durata di una richiesta, poi la chiude."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

> **💡 Perché SQLAlchemy**
>
> Invece di scrivere SQL a mano per ogni operazione, usi **SQLAlchemy**, un **ORM** (*Object-Relational Mapper*): una libreria che collega le classi Python alle tabelle del database. Una classe `Expense` diventa la tabella `expenses`, un oggetto `Expense` diventa una riga. Sai già cos'è: è l'equivalente di JPA/Hibernate in Java o di Eloquent in PHP.


> **📖 Il codice, a blocchi**
>
> - `create_engine(...)` crea l'**engine**: il collegamento al database. `connect_args` con `check_same_thread=False` serve solo a SQLite, perché FastAPI gestisce le richieste in più thread.
> - `sessionmaker(...)` produce **sessioni**. Una sessione è una "conversazione" con il database: leggi, aggiungi, modifichi oggetti e poi con `commit()` salvi tutto insieme. `expire_on_commit=False` evita che gli oggetti si "svuotino" dopo il salvataggio, così puoi ancora leggerli per restituirli.
> - `class Base(DeclarativeBase)`: la classe madre di tutti i modelli. Ogni tabella la estenderà.
> - `get_db()` è un **generatore**: apre una sessione, la consegna (`yield`) a chi la chiede e, qualunque cosa succeda, la chiude (`finally`). FastAPI la userà come **dipendenza** (la vedremo al Passo 20): ogni richiesta ottiene la sua sessione e la restituisce a fine lavoro.


## Passo 17 · Il modello Expense

**Cosa facciamo.** Descriviamo la tabella delle spese come classe Python.

Crea `backend/app/models/expense.py`:

**`backend/app/models/expense.py`**

```python
from datetime import date

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Expense(Base):
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(primary_key=True)
    description: Mapped[str] = mapped_column(String(200))
    # Importi in centesimi (intero): i numeri decimali sbagliano i conti sui soldi
    amount_cents: Mapped[int]
    kind: Mapped[str] = mapped_column(String(10), default="expense")  # "expense" | "income"
    category: Mapped[str] = mapped_column(String(50), default="altro")
    spent_on: Mapped[date]
```

e `backend/app/models/__init__.py`:

**`backend/app/models/__init__.py`**

```python
from app.models.expense import Expense

__all__ = ["Expense"]
```

> **📖 Il codice**
>
> - `__tablename__ = "expenses"` è il nome della tabella.
> - `id: Mapped[int] = mapped_column(primary_key=True)`: ogni riga ha un numero identificativo assegnato dal database. `Mapped[int]` dichiara il tipo Python; SQLAlchemy ne ricava il tipo SQL.
> - `Mapped[str] = mapped_column(String(200))` limita la lunghezza del testo. Per `Mapped[date]` e `Mapped[int]` senza altro, SQLAlchemy sceglie da solo `DATE` e `INTEGER`.
> - `amount_cents`: l'importo è un **intero in centesimi**, non un numero decimale. I decimali binari (`float`) sbagliano i conti sui soldi (0,1 + 0,2 dà 0,30000000000000004); con i centesimi interi i conti sono esatti. Il frontend dividerà per 100 per mostrare gli euro.
> - `kind` distingue `"expense"` (uscita) da `"income"` (entrata); `category` è un testo libero.


> **💡 Perché `__init__.py` importa il modello**
>
> SQLAlchemy conosce solo i modelli che sono stati **importati** prima di creare le tabelle. Mettere gli import in `models/__init__.py` ci permette di scrivere `from app import models` nel `main.py` e sapere che tutte le tabelle sono registrate. A ogni nuovo modello aggiungeremo una riga qui.


## Passo 18 · Gli schemi Pydantic

**Cosa facciamo.** Descriviamo la forma dei dati che entrano ed escono dall'API.

Crea `backend/app/schemas/expense.py`:

**`backend/app/schemas/expense.py`**

```python
from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ExpenseCreate(BaseModel):
    description: str = Field(min_length=1, max_length=200)
    amount_cents: int = Field(gt=0, description="Importo in centesimi, sempre positivo")
    kind: Literal["expense", "income"] = "expense"
    category: str = Field(default="altro", min_length=1, max_length=50)
    spent_on: date


class ExpenseRead(ExpenseCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int


class CategoryTotal(BaseModel):
    category: str
    total_cents: int


class MonthSummary(BaseModel):
    month: str
    income_cents: int
    expense_cents: int
    balance_cents: int
    by_category: list[CategoryTotal]
```

> **💡 Perché separare schemi e modelli**
>
> Il **modello** descrive come i dati sono salvati nel database. Lo **schema** descrive che cosa accetti e che cosa restituisci via web. Non sono la stessa cosa: l'identificativo `id` esiste in uscita ma non lo vuoi in ingresso (lo decide il database); una password sta nel modello ma non deve mai uscire dallo schema. Tenerli separati ti evita di esporre per errore qualcosa e ti permette di cambiare il database senza cambiare l'API.


> **📖 Il codice**
>
> - Le classi estendono `BaseModel` di **Pydantic**, che **valida** i dati: se arriva un importo di testo o un campo mancante, FastAPI risponde **422** con un messaggio chiaro, e il tuo codice non vede mai dati sporchi.
> - `Field(min_length=1, max_length=200)` e `Field(gt=0)` fissano vincoli: descrizione non vuota, importo maggiore di zero.
> - `Literal["expense", "income"]` ammette solo quei due valori.
> - `ExpenseRead` **eredita** da `ExpenseCreate` aggiungendo `id`. `from_attributes=True` permette a Pydantic di leggere i dati direttamente da un oggetto del database (`Expense`) e non solo da un dizionario.
> - `MonthSummary` e `CategoryTotal` descrivono la risposta del riepilogo mensile.


## Passo 19 · Il servizio (la logica)

**Cosa facciamo.** Scriviamo le funzioni che fanno il lavoro vero sulle spese.

Crea `backend/app/services/expenses.py`:

**`backend/app/services/expenses.py`**

```python
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.expense import Expense
from app.schemas.expense import CategoryTotal, ExpenseCreate, MonthSummary

MONTH_PATTERN = r"^\d{4}-(0[1-9]|1[0-2])$"


def month_range(month: str) -> tuple[date, date]:
    """'2026-10' -> (1 ottobre 2026, 1 novembre 2026): inizio incluso, fine esclusa."""
    year, mon = (int(part) for part in month.split("-"))
    start = date(year, mon, 1)
    end = date(year + (mon == 12), mon % 12 + 1, 1)
    return start, end


def create_expense(db: Session, data: ExpenseCreate) -> Expense:
    expense = Expense(**data.model_dump())
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def list_expenses(db: Session, month: str | None = None) -> list[Expense]:
    stmt = select(Expense).order_by(Expense.spent_on.desc(), Expense.id.desc())
    if month:
        start, end = month_range(month)
        stmt = stmt.where(Expense.spent_on >= start, Expense.spent_on < end)
    return list(db.scalars(stmt))


def delete_expense(db: Session, expense_id: int) -> bool:
    expense = db.get(Expense, expense_id)
    if expense is None:
        return False
    db.delete(expense)
    db.commit()
    return True


def month_summary(db: Session, month: str) -> MonthSummary:
    start, end = month_range(month)
    stmt = (
        select(Expense.kind, Expense.category, func.sum(Expense.amount_cents))
        .where(Expense.spent_on >= start, Expense.spent_on < end)
        .group_by(Expense.kind, Expense.category)
    )
    income = 0
    expense = 0
    by_category: list[CategoryTotal] = []
    for kind, category, total in db.execute(stmt):
        if kind == "income":
            income += total
        else:
            expense += total
            by_category.append(CategoryTotal(category=category, total_cents=total))
    by_category.sort(key=lambda item: item.total_cents, reverse=True)
    return MonthSummary(
        month=month,
        income_cents=income,
        expense_cents=expense,
        balance_cents=income - expense,
        by_category=by_category,
    )
```

> **📖 Le funzioni**
>
> - `month_range("2026-10")` restituisce la coppia (1 ottobre, 1 novembre): inizio **incluso**, fine **esclusa**. Gli intervalli "da incluso a escluso" evitano il classico problema degli ultimi giorni del mese (28, 30 o 31?) e di dicembre: la formula `year + (mon == 12)` passa all'anno dopo.
> - `create_expense` costruisce l'oggetto dal dato validato (`data.model_dump()` lo trasforma in dizionario), lo aggiunge alla sessione, fa `commit()` e `refresh()` per leggere l'`id` assegnato.
> - `list_expenses` costruisce una query con `select(...)`, la ordina (le più recenti prima) e, se è indicato un mese, aggiunge il filtro sulle date.
> - `delete_expense` restituisce `True` o `False`: sarà l'endpoint a decidere che cosa farne (404 se non esiste).
> - `month_summary` usa `func.sum` e `group_by` per far calcolare i totali **al database** (veloce) invece di sommare a mano in Python, poi separa entrate e uscite e ordina le categorie dalla più costosa.


> **💡 Perché il servizio non sa nulla del web**
>
> Guarda gli import: niente `fastapi`. Il servizio riceve una sessione e dei dati e restituisce oggetti Python. Non conosce indirizzi, codici di stato o JSON. Per questo si può usare e provare da solo, e domani lo potresti richiamare da uno script o da un assistente senza cambiare nulla.


## Passo 20 · Le dipendenze condivise (deps.py)

**Cosa facciamo.** Creiamo il file dove definiremo ciò che gli endpoint si fanno "consegnare" da FastAPI.

Crea `backend/app/api/deps.py`:

**`backend/app/api/deps.py`**

```python
from typing import Annotated

from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.database import get_db

# Una sessione del database per richiesta
DbSession = Annotated[Session, Depends(get_db)]
```

> **💡 Perché le dipendenze**
>
> Questa è l'**iniezione delle dipendenze** (*dependency injection*): invece di far aprire a ogni endpoint la propria connessione al database, dichiari "mi serve una sessione" e FastAPI la crea, la passa e la chiude. Il vantaggio enorme è nei test: puoi **sostituire** `get_db` con una versione che usa un database finto in memoria, senza toccare gli endpoint. Lo farai al Passo 23.


> **📖 La riga chiave**
>
> `DbSession = Annotated[Session, Depends(get_db)]` crea un "tipo" riutilizzabile. In un endpoint scriverai `def mia_funzione(db: DbSession)` e `db` sarà una sessione pronta all'uso. Più avanti qui aggiungeremo le altre dipendenze (il parser di Gemini, il provider di Google Calendar).


## Passo 21 · Gli endpoint delle spese

**Cosa facciamo.** Esponiamo le funzioni del servizio come indirizzi web.

Crea `backend/app/api/v1/endpoints/expenses.py`:

**`backend/app/api/v1/endpoints/expenses.py`**

```python
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query

from app.api.deps import DbSession
from app.schemas.expense import ExpenseCreate, ExpenseRead, MonthSummary
from app.services import expenses as service
from app.services.expenses import MONTH_PATTERN

router = APIRouter()

MonthRequired = Annotated[str, Query(pattern=MONTH_PATTERN, description="Formato YYYY-MM")]
MonthOptional = Annotated[str | None, Query(pattern=MONTH_PATTERN, description="Formato YYYY-MM")]


@router.post("", response_model=ExpenseRead, status_code=201)
def create_expense(data: ExpenseCreate, db: DbSession):
    return service.create_expense(db, data)


@router.get("", response_model=list[ExpenseRead])
def list_expenses(db: DbSession, month: MonthOptional = None):
    return service.list_expenses(db, month)


# Attenzione all'ordine: i percorsi fissi ("/summary") vanno prima di quelli con parametro
@router.get("/summary", response_model=MonthSummary)
def month_summary(db: DbSession, month: MonthRequired):
    return service.month_summary(db, month)


@router.delete("/{expense_id}", status_code=204)
def delete_expense(expense_id: int, db: DbSession) -> None:
    if not service.delete_expense(db, expense_id):
        raise HTTPException(status_code=404, detail="Spesa non trovata")
```

Poi aggiorna `backend/app/api/v1/router.py` per collegarlo:

**`backend/app/api/v1/router.py`**

```python
from fastapi import APIRouter

from app.api.v1.endpoints import expenses, health

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["expenses"])
```

> **📖 Il codice**
>
> - Ogni funzione ha un **decoratore** che dice metodo e indirizzo: `@router.post("")`, `@router.get("")`, `@router.get("/summary")`, `@router.delete("/{expense_id}")`. Il prefisso `/expenses` viene dal `router.py`, quindi gli indirizzi finali sono `/api/v1/expenses`, `/api/v1/expenses/summary` ecc.
> - `response_model=ExpenseRead` dice a FastAPI quale schema usare per costruire la risposta: filtra i campi e li documenta. `status_code=201` segnala "creato".
> - `data: ExpenseCreate` come parametro significa "il corpo JSON della richiesta deve rispettare questo schema": FastAPI lo legge, lo valida e te lo consegna già pronto.
> - `{expense_id}` nell'indirizzo è un **parametro di percorso**; con `expense_id: int` FastAPI lo converte e lo valida.
> - `month` è un **parametro di query** (`?month=2026-10`) validato da un'espressione regolare con `Query(pattern=...)`: `2026-13` viene rifiutato con 422.
> - `raise HTTPException(status_code=404, ...)` interrompe e risponde con l'errore indicato.
> - L'endpoint non contiene logica: chiama `service.create_expense(db, data)` e restituisce. Questo è lo "endpoint sottile" di cui parlavamo.


> **⚠️ L'ordine conta**
>
> `/summary` è dichiarato **prima** di `/{expense_id}`. Le rotte vengono confrontate nell'ordine in cui sono scritte (come in Express): se `/{expense_id}` venisse prima, la richiesta a `/summary` verrebbe presa come un `expense_id` uguale a "summary". Regola: **i percorsi fissi prima, quelli con parametro dopo.**


## Passo 22 · main.py definitivo

**Cosa facciamo.** Completiamo `main.py`: creazione delle tabelle all'avvio e impostazione del CORS.

Sostituisci il contenuto di `backend/app/main.py`:

**`backend/app/main.py`**

```python
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import models  # noqa: F401  (importarlo registra le tabelle)
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import Base, engine


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    # All'avvio: crea le tabelle che non esistono ancora
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Gestionale Personale", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")
```

> **📖 Il codice**
>
> - `from app import models` serve solo a **registrare** le tabelle (importare il pacchetto esegue `models/__init__.py`); il commento `noqa` dice al controllo di stile "so che non lo uso direttamente".
> - `lifespan` è il codice che gira **all'avvio** (prima di `yield`) e allo spegnimento (dopo). All'avvio chiamiamo `Base.metadata.create_all(bind=engine)`: crea nel database le tabelle che non esistono ancora.
> - **CORS**: i browser, per sicurezza, impediscono a una pagina servita da un indirizzo (`localhost:5173`) di chiamare un altro indirizzo (`localhost:8000`) a meno che quest'ultimo lo autorizzi. Il `CORSMiddleware` lo autorizza per gli indirizzi in `cors_origins`. Nel nostro frontend useremo anche un *proxy* che rende la cosa trasparente, ma tenere il CORS configurato non costa nulla ed evita sorprese.


> **⚠️ Attenzione: `create_all` non modifica le tabelle esistenti**
>
> `create_all` crea le tabelle mancanti, ma se in seguito **aggiungi o cambi una colonna** a un modello, non aggiorna la tabella già creata. Mentre sviluppi, con dati di prova, la soluzione più semplice è **cancellare il file `gestionale.db`** e riavviare: verrà ricreato. Quando i dati diventeranno preziosi userai le **migrazioni** (Alembic, Parte 10).


## Passo 23 · I test delle spese

**Cosa facciamo.** Scriviamo il file di configurazione dei test e i test delle spese.

Crea `backend/tests/conftest.py`:

**`backend/tests/conftest.py`**

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app


@pytest.fixture()
def client():
    # Database solo in memoria: sparisce a fine test, il vero file non viene toccato
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(engine)
    testing_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    def override_get_db():
        db = testing_session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    # Senza "with": la fase di avvio (lifespan) non parte e il vero database non viene creato
    yield TestClient(app)
    app.dependency_overrides.clear()
    engine.dispose()
```

Sostituisci `backend/tests/test_health.py` con la versione che usa il `client` fornito dal `conftest`:

**`backend/tests/test_health.py`**

```python
def test_health(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

Crea `backend/tests/test_expenses.py`:

**`backend/tests/test_expenses.py`**

```python
from datetime import date

from app.services.expenses import month_range


def make_expense(client, **changes):
    payload = {
        "description": "Spesa",
        "amount_cents": 1250,
        "kind": "expense",
        "category": "cibo",
        "spent_on": "2026-10-05",
    }
    payload.update(changes)
    response = client.post("/api/v1/expenses", json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_create_and_list(client):
    created = make_expense(client)
    assert created["id"] == 1
    response = client.get("/api/v1/expenses")
    assert response.status_code == 200
    assert [item["description"] for item in response.json()] == ["Spesa"]


def test_month_filter(client):
    make_expense(client, spent_on="2026-10-05")
    make_expense(client, spent_on="2026-11-01")
    response = client.get("/api/v1/expenses", params={"month": "2026-10"})
    assert [item["spent_on"] for item in response.json()] == ["2026-10-05"]


def test_summary(client):
    make_expense(client, kind="income", amount_cents=100000, category="stipendio")
    make_expense(client, amount_cents=1250, category="cibo")
    make_expense(client, amount_cents=3000, category="cibo")
    make_expense(client, amount_cents=2000, category="trasporti")
    make_expense(client, amount_cents=999, category="cibo", spent_on="2026-09-30")  # altro mese

    data = client.get("/api/v1/expenses/summary", params={"month": "2026-10"}).json()
    assert data["income_cents"] == 100000
    assert data["expense_cents"] == 6250
    assert data["balance_cents"] == 93750
    assert data["by_category"] == [
        {"category": "cibo", "total_cents": 4250},
        {"category": "trasporti", "total_cents": 2000},
    ]


def test_validation(client):
    bad_amount = {"description": "x", "amount_cents": 0, "spent_on": "2026-10-05"}
    assert client.post("/api/v1/expenses", json=bad_amount).status_code == 422
    assert client.get("/api/v1/expenses/summary", params={"month": "2026-13"}).status_code == 422
    assert client.get("/api/v1/expenses/summary").status_code == 422  # month obbligatorio


def test_delete(client):
    created = make_expense(client)
    assert client.delete(f"/api/v1/expenses/{created['id']}").status_code == 204
    assert client.delete(f"/api/v1/expenses/{created['id']}").status_code == 404


def test_month_range_handles_december():
    assert month_range("2026-12") == (date(2026, 12, 1), date(2027, 1, 1))
    assert month_range("2026-02") == (date(2026, 2, 1), date(2026, 3, 1))
```

Lancia `pytest`.

> **💡 Perché un database finto**
>
> I test devono essere veloci, ripetibili e **non toccare i tuoi dati veri**. Il `conftest.py` crea per ogni test un database SQLite **in memoria**, vuoto e usa-e-getta, e dice a FastAPI di usarlo al posto del vero (`dependency_overrides`). È l'iniezione delle dipendenze che ripaga.


> **📖 Le parti nuove**
>
> - `conftest.py` è un file speciale di pytest: ciò che definisce è disponibile a tutti i test senza importarlo.
> - `@pytest.fixture()` definisce una **fixture**: una "preparazione" che pytest esegue per te. Un test che ha un parametro chiamato `client` riceve il valore restituito da quella fixture. Tutto ciò che sta dopo `yield` è la pulizia a fine test.
> - `StaticPool` fa sì che tutte le connessioni condividano **lo stesso** database in memoria (altrimenti ogni connessione ne vedrebbe uno vuoto diverso).
> - Il `TestClient` è creato **senza** `with`: in questo modo la fase di avvio (`lifespan`) non parte e `create_all` non crea il vero `gestionale.db` durante i test.
> - In `test_expenses.py` la funzione `make_expense` è un **aiuto** per non ripetere il corpo della richiesta; ogni `test_...` verifica un comportamento: creazione, filtro per mese, riepilogo (con una spesa di un altro mese che deve essere esclusa), validazione (422), cancellazione (204 poi 404), calcolo dei mesi.


> **✅ Verifica**
>
> `pytest` mostra tutti i test verdi (`7 passed`: uno di salute e sei delle spese).


## Passo 24 · Provare le spese da /docs

**Cosa facciamo.** Proviamo l'endpoint "dal vivo", con il database vero.

1. Avvia il server: `uvicorn app.main:app --reload`.
2. Apri **http://127.0.0.1:8000/docs**: ora trovi la sezione **expenses**.
3. Apri `POST /api/v1/expenses`, premi **Try it out**, scrivi un corpo come questo e premi **Execute**:

**`Corpo della richiesta`**

```text
{
  "description": "Pizza",
  "amount_cents": 850,
  "kind": "expense",
  "category": "cibo",
  "spent_on": "2026-10-08"
}
```

4. Dovresti ricevere **201** e la spesa con il suo `id`. Prova poi `GET /api/v1/expenses` e `GET /api/v1/expenses/summary` con `month` uguale a `2026-10`.
5. Nella cartella `backend` è comparso il file **`gestionale.db`**: è il tuo database. Per guardarci dentro puoi installare in VS Code l'estensione *SQLite Viewer*.

> **✅ Verifica**
>
> La pizza compare nell'elenco e il riepilogo mostra 850 centesimi di uscite nella categoria `cibo`. Fai un commit: `git add .` e `git commit -m "Spese: modello, servizio, endpoint e test"`.


> **📝 Hai capito il percorso?**
>
> Rileggi i passi 17-21: **modello** (come salvi), **schema** (come comunichi), **servizio** (cosa fai), **endpoint** (a quale indirizzo), **test** (come verifichi). Per ogni nuova funzione che aggiungerai in futuro seguirai lo stesso ordine.



---

# Dove sei arrivato e cosa viene dopo

## Che cosa hai costruito

Con le Parti 1, 2 e 3 hai realizzato il **programma base**: uno scheletro di backend moderno, ordinato a livelli, con database, test automatici e una prima funzionalità completa (le spese). Ricapitolando:

| Parte | Risultato |
|---|---|
| 1 | Cartella, ambiente virtuale, FastAPI e un server che risponde `ok`; Git |
| 2 | Test automatici e struttura a livelli (`api`, `services`, `models`, `schemas`, `core`) |
| 3 | Configurazione, database SQLite, e il percorso completo modello, schema, servizio, endpoint, test (spese) |

> **📝 La cosa più importante da portarti via**
>
> Il percorso **modello, schema, servizio, endpoint, test** è lo stampo di ogni funzionalità futura. Progetti, orario universitario, calendario e pianificatore sono tutte variazioni di questo stesso schema.


## Prossimi passi (funzionalità specifiche)

Le funzionalità specifiche si aggiungono sopra questa base, una alla volta:

1. **Progetti in corso**: ripetizione dello schema delle spese (priorità, scadenza, ultimo lavoro).
2. **Orario universitario**: caricamento CSV/Excel, normalizzazione con Gemini, anteprima e conferma.
3. **Google Calendar**: login OAuth e lettura degli eventi in sola lettura.
4. **Tempo libero e attività proposte**: calcolo delle fasce libere e punteggi.
5. **Frontend React**: le pagine Oggi, Orario, Progetti, Spese.
6. **Parte agentica, migrazioni, Postgres, Docker**.

## Routine di ogni sessione di lavoro

1. Apri VS Code nella cartella `gestionale_personale`.
2. Apri il terminale e vai in `backend`: `cd backend`.
3. Attiva l'ambiente: PowerShell `.venv\Scripts\Activate.ps1`; cmd `.venv\Scripts\activate`. Devi vedere `(.venv)` a sinistra.
4. Avvia il server: `uvicorn app.main:app --reload` e apri `http://127.0.0.1:8000/docs`.
5. Prima di fermarti: `pytest`, poi `git add .` e `git commit -m "messaggio"`.

## Errori frequenti

| Sintomo | Causa probabile | Soluzione |
|---|---|---|
| `ModuleNotFoundError: No module named 'app'` | Fuori da `backend`, oppure progetto non installato | `cd backend` e `pip install -e ".[dev]"` |
| `'uvicorn' non riconosciuto` | Ambiente virtuale non attivo | Attiva `.venv` |
| `Activate.ps1` non fa nulla in cmd | Quello è per PowerShell | In cmd: `.venv\Scripts\activate` |
| `python3` non trovato | Su Windows il comando è `python` | Usa `python` |
| Errore su nome progetto | Spazio nel nome in `pyproject.toml` | Usa `gestionale-personale` |
| Errore su `dependecies` | Refuso nella parola | Scrivi `dependencies` |
| `Address already in use` | Server già avviato in un altro terminale | Chiudilo o usa `--port 8001` |
| Nuova colonna non compare | `create_all` non modifica le tabelle esistenti | Cancella `gestionale.db` e riavvia |
| 404 su `/health` | Dalla Parte 2 vive in `/api/v1/health` | Usa il nuovo indirizzo |
| 422 sulle richieste | Dati non validi rispetto allo schema | Leggi il campo `detail` della risposta |


---
