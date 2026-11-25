"""Demonstra o OrquestradorSessao com séries sintéticas, sem câmera."""

from typing import Dict, List, Sequence, Tuple

import numpy as np

from avaliador_pontuacao import (
    OrquestradorSessao,
    ResultadoPontuacaoRepeticao,
    ResumoPontuacaoSessao,
)


FrameAngulos = Dict[str, float]


def criar_frames_movimento_completo(total_frames: int) -> List[FrameAngulos]:
    """Gera uma repetição sintética de desenvolvimento de ombro."""
    margem = 5
    frames_movimento = total_frames - 2 * margem
    if frames_movimento < 3:
        raise ValueError("A série precisa ter ao menos três frames de movimento.")

    frames: List[FrameAngulos] = [
        {"cotovelo": 90.0, "ombro": 80.0} for _ in range(margem)
    ]
    for angulo in np.linspace(0.0, np.pi, frames_movimento):
        seno = float(np.sin(angulo))
        frames.append(
            {
                "cotovelo": 90.0 + 75.0 * seno,
                "ombro": 80.0 + 75.0 * seno,
            }
        )
    frames.extend(
        {"cotovelo": 90.0, "ombro": 80.0} for _ in range(margem)
    )
    return frames


def criar_frames_movimento_incompleto() -> List[FrameAngulos]:
    """Gera uma repetição interrompida antes de alcançar o pico do movimento."""
    cotovelos = (90.0, 90.0, 105.0, 115.0, 120.0, 118.0, 112.0, 105.0, 95.0, 90.0)
    return [{"cotovelo": angulo, "ombro": 80.0} for angulo in cotovelos]


def executar_sessao(
    frames: Sequence[FrameAngulos],
) -> Tuple[ResultadoPontuacaoRepeticao, ResumoPontuacaoSessao]:
    """Envia cada frame ao orquestrador e devolve o laudo e o resumo da sessão."""
    orquestrador = OrquestradorSessao("1")
    resultados: List[ResultadoPontuacaoRepeticao] = []
    for angulos in frames:
        _, resultado = orquestrador.processar_frame(angulos=angulos, visivel=True)
        if resultado is not None:
            resultados.append(resultado)

    if len(resultados) != 1:
        raise RuntimeError(
            f"Esperada uma repetição concluída, mas foram geradas {len(resultados)}."
        )

    return resultados[0], orquestrador.gerar_resumo_sessao()


def exibir_resultado(
    nome_cenario: str,
    resultado: ResultadoPontuacaoRepeticao,
    resumo: ResumoPontuacaoSessao,
) -> None:
    """Exibe o laudo da repetição e o resumo gerado pelo orquestrador."""
    veredito = "APROVADA" if resultado.aprovado else "REPROVADA"
    erros = ", ".join(resultado.erros_fsm) if resultado.erros_fsm else "nenhum"
    print(
        f"{nome_cenario}: nota {resultado.score_final:.1f}/100 "
        f"({resultado.classificacao}) - {veredito}"
    )
    print(f"  Penalidade FSM: {resultado.penalidade_fsm:.1f}")
    print(f"  Erros FSM: {erros}")
    print(f"  Feedback: {resultado.feedback_principal}")
    print(
        f"  Resumo: {resumo.total_repeticoes} repetição(ões), "
        f"{resumo.repeticoes_aprovadas} aprovada(s), "
        f"{resumo.repeticoes_reprovadas} reprovada(s), "
        f"média {resumo.score_medio:.1f}"
    )
    print(f"  Recomendação: {resumo.recomendacao_prioritaria}")


def main() -> None:
    """Executa cenários ideal, lento/muito lento e incompleto."""
    print("=== Demonstração do OrquestradorSessao (Desenvolvimento de Ombro) ===")

    ideal, resumo_ideal = executar_sessao(criar_frames_movimento_completo(55))
    exibir_resultado("Ideal (55 frames)", ideal, resumo_ideal)
    if ideal.score_final < 95.0 or not ideal.aprovado or ideal.erros_fsm:
        raise RuntimeError("O cenário ideal não atingiu os critérios esperados.")

    for total_frames in (65, 150):
        lento, resumo_lento = executar_sessao(
            criar_frames_movimento_completo(total_frames)
        )
        rotulo = "Lento" if total_frames == 65 else "Muito lento"
        exibir_resultado(f"{rotulo} ({total_frames} frames)", lento, resumo_lento)
        if lento.score_final < 85.0 or not lento.aprovado or lento.erros_fsm:
            raise RuntimeError(
                f"O cenário de {total_frames} frames não atingiu os critérios esperados."
            )

    incompleto, resumo_incompleto = executar_sessao(
        criar_frames_movimento_incompleto()
    )
    exibir_resultado("Incompleto", incompleto, resumo_incompleto)
    if (
        incompleto.aprovado
        or incompleto.penalidade_fsm != 25.0
        or "REPETICAO_INCOMPLETA" not in incompleto.erros_fsm
    ):
        raise RuntimeError("O cenário incompleto não foi penalizado e reprovado.")


if __name__ == "__main__":
    main()
