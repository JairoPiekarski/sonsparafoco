# 🧘 Focus Sounds App

Um aplicativo de bem-estar desenvolvido em Flutter, projetado para auxiliar no foco e relaxamento através de sons ambientes (Chuva, Vento, Fogo). O projeto foca em uma arquitetura limpa, modular e com gerenciamento de estado eficiente.

## 🚀 Funcionalidades

- **Sons Ambientes:** Reprodução em loop de áudios de alta qualidade.
- **Temporizador Inteligente:** Opções de 15, 30 e 60 minutos com desligamento automático do áudio.
- **Controle de Volume:** Slider integrado para ajuste fino da imersão.
- **UI Responsiva:** Interface escura (Dark Theme) otimizada para reduzir a fadiga visual.

## 🛠️ Arquitetura e Tecnologias

Este projeto foi estruturado seguindo princípios de **Clean Code** e **Componentização**:

- **Flutter & Dart:** Framework e linguagem base.
- **Audioplayers:** Biblioteca para manipulação de fluxos de áudio.
- **Modularização:** Separação clara entre inicialização (`main.dart`), telas (`screens/`) e componentes reaproveitáveis (`widgets/`).
- **Gerenciamento de Estado:** Uso de `StatefulWidgets` com controle preciso do ciclo de vida do áudio e timers (evitando memory leaks com `dispose`).

## 🛡️ Contexto de Cibersegurança

Como desenvolvedor focado em segurança, este projeto serviu para explorar:
- **Gerenciamento de Recursos:** Garantir que processos de áudio e timers sejam finalizados corretamente para evitar ataques de negação de serviço local por exaustão de memória.
- **Arquitetura Modular:** Redução da superfície de ataque e facilidade em futuras auditorias de código através da separação de responsabilidades.

## 📦 Como rodar o projeto

1. Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
2. Clone o repositório:
   ```
   git clone [https://github.com/seu-usuario/seu-repositorio.git](https://github.com/seu-usuario/seu-repositorio.git)
   ```
3. Instale as dependências:
   ```
   flutter pub get
   ```
4. Execute o app:
   ```
   flutter run
   ```

Desenvolvido por [Jairo Vinicius Piekarski](https://linkedin.com/in/jairo-vinicius-piekarski-698959191/)
