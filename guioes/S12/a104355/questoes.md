# Semana 12 - Injecao SQL e de Comandos

## Exercicio 1 - Reconhecimento de SQL injection

### Pesquisa normal: `Welcome`

Resultado esperado:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%Welcome%'
  [1] Welcome: This is your first note.
```

Isto e o comportamento normal: a aplicacao procura titulos que contenham a substring `Welcome`.

### Payload 1: `' OR '1'='1`

Resultado observado:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' OR '1'='1%'
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
```

Este payload fecha a string do `LIKE` logo depois de `'%`, transformando a query numa expressao booleana onde `title LIKE '%'` fica sempre verdadeira. Como qualquer titulo nao vazio faz match com `%`, o atacante obtem todas as notas, incluindo a nota `Secret`.

### Payload 2: `' UNION SELECT 1, sql, '' FROM sqlite_master --`

Resultado observado:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' UNION SELECT 1, sql, '' FROM sqlite_master --%'
  [1] CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT, body TEXT):
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
```

Este payload usa `UNION SELECT` para anexar ao resultado original uma linha vinda de `sqlite_master`, a tabela interna que guarda o schema da base de dados SQLite. Assim, o atacante nao so le dados das notas como tambem descobre a estrutura da tabela (`CREATE TABLE notes ...`).

### Payload 3: `' UNION SELECT 1, title, body FROM notes --`

Resultado observado:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE '%' UNION SELECT 1, title, body FROM notes --%'
  [1] Reminder: Submit the SSI lab report on time.
  [1] Secret: The admin password is hunter2.
  [1] Welcome: This is your first note.
  [2] Reminder: Submit the SSI lab report on time.
  [3] Secret: The admin password is hunter2.
```

Este payload injeta outra query que seleciona diretamente `title` e `body` da tabela `notes`. Ou seja, mesmo que a aplicacao tivesse filtros de apresentacao diferentes, um atacante pode reconstruir uma query arbitraria e extrair o conteudo que quiser, incluindo segredos.

### O que cada payload faz e porque funciona

- O primeiro payload altera a logica do `WHERE`, transformando uma pesquisa normal numa condicao sempre verdadeira.
- O segundo payload usa `UNION SELECT` para juntar linhas do schema interno da base de dados.
- O terceiro payload usa `UNION SELECT` para voltar a ler a propria tabela de dados com uma query injetada.

Tudo isto funciona porque a aplicacao concatena texto controlado pelo utilizador diretamente na query SQL. A base de dados deixa de receber um "valor de pesquisa" e passa a receber fragmentos de codigo SQL.

### Que informacao pode um atacante extrair?

Um atacante pode extrair:

- todas as notas da tabela
- segredos guardados nas notas
- a estrutura das tabelas e colunas
- possivelmente dados de outras tabelas existentes na mesma base de dados

Em sistemas reais, isto pode expor:

- passwords
- hashes
- emails
- tokens
- dados pessoais ou financeiros

## Exercicio 2 - Command injection

### Payload 1: `note.txt`

Resultado normal:

```text
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt
  Note exported to note.txt
```

E criado o ficheiro `note.txt` com o conteudo esperado.

### Payload 2: `note.txt; cat /etc/passwd`

Resultado observado em Linux:

```text
root:x:0:0:root:/root:/bin/bash
...
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt; cat /etc/passwd
  Note exported to note.txt; cat /etc/passwd
```

Em execucao real, a ordem entre a linha de debug e o output injetado pode variar por causa do buffering do Python e da shell, mas o efeito de seguranca e o mesmo: o `cat /etc/passwd` foi executado.

### Payload 3: `note.txt; id; whoami`

Resultado observado em Linux:

```text
uid=1000(ssi) gid=1000(ssi) groups=1000(ssi),27(sudo),110(docker),988(vboxsf)
ssi
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > note.txt; id; whoami
  Note exported to note.txt; id; whoami
```

O atacante descobre com que privilegios o processo esta a correr e qual e o utilizador efetivo.

### Payload 4: `` `ls -la` ``

Resultado observado em Linux:

```text
[DEBUG] Executing command: echo 'Title: Welcome
Body: This is your first note.' > `ls -la`
  Note exported to `ls -la`
sh: 1: cannot create total 32
drwx------  3 ssi  ssi  4096 May  4 13:18 .
drwxrwxrwt 14 root root 4096 May  4 13:18 ..
...
__pycache__: File name too long
```

Mesmo quando o resultado final e um erro, a shell tenta expandir a substituicao por backticks. Isto mostra que o input nao esta a ser tratado como "nome de ficheiro", mas sim como parte de um comando shell.

### Porque a aplicacao e vulneravel?

A aplicacao construi uma string de shell com input do utilizador e entrega-a a `os.system()`. Isto da ao atacante controlo sobre a linha de comando. Em vez de apenas escolher um nome de ficheiro, o atacante consegue injetar separadores de comandos, substituicao por backticks, pipes, redirecionamentos e assim por diante.

### O que um atacante poderia alcancar num servidor real?

Num servidor real, um atacante poderia:

- ler ficheiros locais sensiveis
- descobrir informacao sobre o sistema
- alterar ou apagar ficheiros
- descarregar malware
- mover-se lateralmente se existirem credenciais acessiveis

O impacto depende dos privilegios do utilizador do servico. Quanto mais privilegios o processo tiver, pior.

## Exercicio 3 - Remediacao segura (SQL injection)

### Funcao corrigida

```python
def search_notes(query):
    """Search notes by title safely using a parameterised query."""
    conn = sqlite3.connect(DB_FILE)
    sql = "SELECT id, title, body FROM notes WHERE title LIKE ?"
    parameter = f"%{query}%"
    print(f"[DEBUG] Executing SQL: {sql} | params=({parameter!r},)")
    try:
        cursor = conn.execute(sql, (parameter,))
        results = cursor.fetchall()
        if results:
            for row in results:
                print(f"  [{row[0]}] {row[1]}: {row[2]}")
        else:
            print("  No notes found.")
    except sqlite3.Error as e:
        print(f"  SQL error: {e}")
    conn.close()
```

### Porque esta correcao e segura

- A query deixa de ser montada por concatenacao.
- O input do utilizador passa a ser um parametro.
- O SQLite trata esse valor como dado literal, nao como SQL executavel.
- Os wildcards `%` continuam a funcionar porque sao adicionados no valor do parametro, nao no codigo SQL.

### Testes depois da correcao

Payloads testados:

- `' OR '1'='1`
- `' UNION SELECT 1, sql, '' FROM sqlite_master --`
- `' UNION SELECT 1, title, body FROM notes --`

Resultado:

```text
[DEBUG] Executing SQL: SELECT id, title, body FROM notes WHERE title LIKE ? | params=("%' OR '1'='1%",)
  No notes found.
```

E de forma equivalente para os restantes payloads: o programa procura literalmente essas strings como texto de pesquisa e nao devolve schema nem notas extra.

## Exercicio 4 - Remediacao segura (command injection)

### Funcao corrigida

```python
def export_note(note_id):
    """Export a note to a file without invoking a shell."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.execute(
        "SELECT title, body FROM notes WHERE id = ?", (note_id,)
    )
    row = cursor.fetchone()
    conn.close()

    if row is None:
        print("  Note not found.")
        return

    filename = input("  Enter filename to export to: ").strip()
    if not is_safe_filename(filename):
        print("  Invalid filename. Use only letters, digits, ., _ and -.")
        return

    output_path = Path(filename)
    payload = f"Title: {row[0]}\\nBody: {row[1]}\\n"
    output_path.write_text(payload, encoding="utf-8")
    print(f"  Note exported to {output_path}")
```

### Porque esta correcao e segura

- `os.system()` desaparece.
- Ja nao existe shell para interpretar `;`, backticks, pipes ou redirecionamentos.
- O nome do ficheiro e validado por regex.
- So sao aceites nomes simples locais, sem metacaracteres nem caminhos.

### Testes depois da correcao

Payloads testados:

- `note.txt`
- `note.txt; cat /etc/passwd`
- `note.txt; id; whoami`
- `` `ls -la` ``

Resultados:

```text
note.txt
  Note exported to note.txt

note.txt; cat /etc/passwd
  Invalid filename. Use only letters, digits, ., _ and -.

note.txt; id; whoami
  Invalid filename. Use only letters, digits, ., _ and -.

`ls -la`
  Invalid filename. Use only letters, digits, ., _ and -.
```

Nenhum payload malicioso volta a ser executado.

## Exercicio 5 - Reflexao

As quatro classes de falhas estudadas nas semanas 11 e 12 partilham a mesma causa base: o programa mistura dados controlados pelo utilizador com estruturas internas que deviam continuar sob controlo do programador. Num buffer overflow, bytes extra invadem memoria adjacente; numa format string vulnerability, o input passa a ser interpretado como instrucoes para `printf`; em SQL injection e command injection, texto do utilizador passa a ser interpretado como codigo por outro interpretador. Em todos os casos, o software deixa de impor uma separacao clara entre "dados" e "comandos".

A validacao de entradas, por si so, e insuficiente porque e facil esquecer casos-limite, variantes de encoding, metacaracteres ou novos contextos de execucao. Mesmo bons filtros podem falhar se a arquitetura continuar a usar concatenacao de strings, `printf(input)` ou chamadas ao shell. A defesa robusta exige mecanismos estruturais: limites de memoria, APIs seguras, parametrizacao e ausencia de shell desnecessaria.

Os principios de parametrizacao e privilegio minimo aplicam-se diretamente aqui. Na Semana 12, a parametrizacao aparece nas queries SQL com `?` e na decisao de escrever ficheiros diretamente sem shell. Na Semana 11, o equivalente e usar funcoes com limite de tamanho e tratar strings de formato como literais fixas. O privilegio minimo reduz dano: um servico com menos permissoes expoe menos memoria, menos ficheiros e menos impacto operacional.

Buffer overflows e format strings diferem no mecanismo. O buffer overflow manipula memoria ao escrever para alem dos limites do buffer, podendo corromper variaveis, canaries e enderecos de retorno. A format string nao precisa de ultrapassar um buffer; em vez disso, convence `printf` a ler argumentos inexistentes da stack ou registos, revelando conteudo interno e, noutros contextos, podendo tambem escrever memoria.
