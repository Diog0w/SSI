import sys
import itertools

def attack_slice(slice_str):
    """Retorna os shifts (0-25) ordenados pela probabilidade de revelar A, E, O, S."""
    frequentes_pt = ['A', 'E', 'O', 'S']
    scores = []
    
    for shift in range(26):
        score = 0
        for char in slice_str:
            dec_char = chr(((ord(char) - ord('A') - shift) % 26) + ord('A'))
            if dec_char in frequentes_pt:
                score += 1
        scores.append((score, shift))
    
    # Ordena os shifts com maior score primeiro
    scores.sort(reverse=True, key=lambda x: x[0])
    return [shift for score, shift in scores[:10]] # Top 10 candidatos por fatia

def main():
    if len(sys.argv) < 4:
        return

    tamanho_chave = int(sys.argv[1])
    criptograma = sys.argv[2].upper()
    palavras = [p.upper() for p in sys.argv[3:]]

    # Dividir em fatias
    fatias = [""] * tamanho_chave
    for i, char in enumerate(criptograma):
        fatias[i % tamanho_chave] += char

    # Obter os melhores shifts para cada fatia
    candidatos_por_fatia = [attack_slice(f) for f in fatias]

    # Testar combinações dos melhores candidatos
    for combinacao_shifts in itertools.product(*candidatos_por_fatia):
        texto_limpo = ""
        for i, char in enumerate(criptograma):
            shift = combinacao_shifts[i % tamanho_chave]
            texto_limpo += chr(((ord(char) - ord('A') - shift) % 26) + ord('A'))
        
        if any(palavra in texto_limpo for palavra in palavras):
            chave = "".join(chr(s + ord('A')) for s in combinacao_shifts)
            print(chave)
            print(texto_limpo)
            return

if __name__ == "__main__":
    main()
