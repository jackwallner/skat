#!/usr/bin/env python3
"""Generate reviewed App Store metadata for every supported ASC locale.

The app UI stays German. Storefront metadata follows the Mahj and Bridge
pattern: every App Store Connect locale is complete, with native copy for
the major storefront languages and explicit English fallbacks for complex
script locales that need native review before publication.

STALE WARNING (2026-08-11): the copy baked into this file still quotes the
pre-raise prices ($1.99 / $9.99 / $29.99) in its subscription paragraphs.
fastlane/metadata/ is now the source of truth and is deliberately price-free:
Guideline 3.1.2 is enforced in the binary, the product page renders the real
per-territory price, and a figure in a description is true in at most one of
175 storefronts once a PPP ladder is applied. Running this as-is would put
wrong prices back into all 50 locales. Strip the price sentences here before
using it again.
"""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
LOCALES_FILE = ROOT / "scripts" / "asc-supported-locales.json"
SUPPORT_URL = "https://jackwallner.github.io/skat/support"
MARKETING_URL = "https://jackwallner.github.io/skat/"
PRIVACY_URL = "https://jackwallner.github.io/skat/privacy-policy"
TERMS_URL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"


def text(
    name: str,
    subtitle: str,
    keywords: str,
    promo: str,
    release: str,
    description: str,
) -> dict[str, str]:
    return {
        "name": name,
        "subtitle": subtitle,
        "keywords": keywords,
        "promotional_text": promo,
        "release_notes": release,
        "description": description,
    }


ENGLISH_DESCRIPTION = """Build confident Skat decisions in short, focused sessions.

Skat Trainer turns the parts beginners need most into clear practice questions. There are no opponents, no timers, and no account. Every answer explains not only what is correct, but why.

FOUR FREE PRACTICE ROOMS

CARDS & BIDDING
Learn the 32-card Skat deck, card values, suits, bidding, the Skat, and the foundations of every round.

GAME TYPES
Recognise trump, Grand, and Null. Match cards to a game plan and practise the rules that shape each decision.

DISCARDING
See twelve cards, choose two to discard, and compare your decision with the trainer's explanation.

TRICK PLAY
Practise following suit, trump, opening lead, trick planning, and the small choices that decide a round.

SKAT+ (OPTIONAL)
The four foundation rooms stay free. Skat+ adds new hands, mistake review, a 90-second Time Challenge, extra exercises, and the Master Table for tougher discards, defence, endplay, and strategy.

MADE FOR LEARNING
Swipeable coaching cards explain the rule on the back. Streaks, realistic teaching hands, and clear feedback make rules easier to remember when you sit down to play.

Skat Trainer is an independent learning app. House rules can differ, so agree on the rules at the table.

SUBSCRIPTIONS AND PURCHASES
Skat+ is available as an auto-renewing monthly subscription for $1.99 per month or yearly subscription for $9.99 per year, each with a 1-week free trial. A permanent Lifetime purchase is also available for $29.99. Payment is charged to your Apple Account at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel them in Account Settings on your device. Terms of Use (Apple's standard EULA): {terms_url}. Privacy Policy: {privacy_url}."""


GERMAN_DESCRIPTION = """Skat Trainer macht dich sicherer in der nächsten Runde. Übe Karten, Reizen, Spielarten, Drücken und Stichspiel in kurzen, klaren Einheiten. Jede Antwort erklärt nicht nur was stimmt, sondern auch warum.

Skat Trainer ist für Anfänger und Wiedereinsteiger gedacht. Ohne Gegner, ohne Zeitdruck und ohne Konto. Du übst genau die Entscheidung, die am Tisch sicherer werden soll.

VIER KOSTENLOSE ÜBUNGSRÄUME

KARTEN & REIZEN
Lerne das 32-Karten-Skatblatt, Kartenwerte, Farben, Reizen, Skat und die wichtigsten Grundlagen für jede Runde.

SPIELARTEN
Erkenne Trumpf, Grand und Null. Ordne Karten einer Spielidee zu und übe die Regeln, die den Spielplan bestimmen.

DRÜCKEN
Sieh zwölf Karten, wähle zwei zum Drücken und vergleiche deine Entscheidung mit der Erklärung des Trainers.

STICHSPIEL
Übe Bedienpflicht, Trumpf, Ausspiel, Stichplanung und die kleinen Entscheidungen, die über eine Runde entscheiden.

SKAT+ (OPTIONALE MITGLIEDSCHAFT)
Die vier Grundlagenräume bleiben dauerhaft kostenlos. Skat+ ergänzt Endlos üben mit neuen Kartenstrukturen, Fehler wiederholen nach einem Lernplan, die Zeit-Challenge mit 90 Sekunden, Zusatzübungen und den Meistertisch für anspruchsvollere Entscheidungen.

FÜR EINSTEIGER GEMACHT
Wischkarten erklären die Regel auf der Rückseite. Lernserien, Lehrhände und klare Rückmeldungen machen die Regeln leichter merkbar, wenn du wieder am Tisch sitzt.

Skat Trainer ist eine unabhängige Lernapp. Hausregeln können abweichen, deshalb gilt am Tisch die gemeinsam vereinbarte Regel.

ABONNEMENTS UND KÄUFE
Skat+ ist als automatisch verlängerndes Monatsabonnement für 1,99 $ pro Monat oder Jahresabonnement für 9,99 $ pro Jahr verfügbar, jeweils mit einer kostenlosen Probe von einer Woche. Alternativ gibt es den dauerhaften Zugang für 29,99 $ als einmaligen Kauf. Die Zahlung wird bei der Kaufbestätigung über deinen Apple Account abgerechnet. Abonnements verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf gekündigt werden. Verwalten oder kündigen kannst du sie in den Account-Einstellungen deines Geräts. Nutzungsbedingungen nach Apples Standard-EULA: {terms_url}. Datenschutzerklärung: {privacy_url}."""


FRENCH_DESCRIPTION = """Progressez au Skat grâce à des séances courtes et ciblées.

Skat Trainer transforme les notions essentielles pour débuter en questions claires. Sans adversaire, sans chronomètre et sans compte. Chaque réponse explique ce qui est juste et pourquoi.

QUATRE SALLES D'ENTRAÎNEMENT GRATUITES

CARTES ET ENCHÈRES
Découvrez le jeu de 32 cartes, la valeur des cartes, les couleurs, les enchères, le Skat et les bases de chaque donne.

TYPES DE JEU
Reconnaissez l'atout, le Grand et le Null. Reliez les cartes à un plan de jeu et entraînez-vous aux règles qui orientent chaque décision.

ÉCART ET PLIS
Choisissez deux cartes à écarter, puis pratiquez fournir, jouer l'atout, entamer et planifier les plis.

SKAT+ (OPTIONNEL)
Les quatre salles de base restent gratuites. Skat+ ajoute des mains inédites, la reprise des erreurs, un défi de 90 secondes, des exercices supplémentaires et la Table des maîtres.

CONÇU POUR APPRENDRE
Les cartes de coaching expliquent la règle au verso. Les séries, les mains pédagogiques et les retours clairs aident à retenir les notions à la table.

Skat Trainer est une application d'apprentissage indépendante. Les règles de maison peuvent varier, convenez donc des règles à la table.

ABONNEMENTS ET ACHATS
Skat+ est proposé avec un abonnement mensuel renouvelé automatiquement à 1,99 $ par mois ou annuel à 9,99 $ par an, chacun avec un essai gratuit d'une semaine. Un accès permanent est aussi disponible pour 29,99 $ en achat unique. Le paiement est débité de votre compte Apple lors de la confirmation. Les abonnements se renouvellent automatiquement sauf annulation au moins 24 heures avant la fin de la période. Conditions d'utilisation, EULA standard d'Apple : {terms_url}. Politique de confidentialité : {privacy_url}."""


SPANISH_DESCRIPTION = """Mejora tus decisiones de Skat en sesiones cortas y concentradas.

Skat Trainer convierte lo que más necesitan los principiantes en preguntas claras. Sin rivales, sin cronómetro y sin cuenta. Cada respuesta explica qué es correcto y por qué.

CUATRO SALAS DE PRÁCTICA GRATUITAS

CARTAS Y SUBASTA
Aprende la baraja de 32 cartas, los valores, los palos, las subastas, el Skat y las bases de cada ronda.

TIPOS DE JUEGO
Reconoce triunfo, Grand y Null. Relaciona tus cartas con un plan y practica las reglas que guían cada decisión.

DESCARTE Y BAZAS
Elige dos cartas para descartar y practica asistir al palo, triunfo, salida y planificación de bazas.

SKAT+ (OPCIONAL)
Las cuatro salas básicas siguen siendo gratuitas. Skat+ añade manos nuevas, repaso de errores, un reto de 90 segundos, ejercicios extra y la Mesa de maestros.

HECHO PARA APRENDER
Las tarjetas deslizables explican la regla por detrás. Las rachas, las manos de enseñanza y los comentarios claros ayudan a recordar lo aprendido en la mesa.

Skat Trainer es una app independiente de aprendizaje. Las reglas de casa pueden variar, así que acordad las reglas antes de jugar.

SUSCRIPCIONES Y COMPRAS
Skat+ ofrece una suscripción mensual autorrenovable de $1.99 al mes o anual de $9.99 al año, ambas con una prueba gratuita de una semana. También hay acceso permanente por $29.99 en una sola compra. El pago se carga a tu cuenta de Apple al confirmar la compra. La suscripción se renueva automáticamente salvo que la canceles al menos 24 horas antes del final del periodo. Condiciones de uso, EULA estándar de Apple: {terms_url}. Política de privacidad: {privacy_url}."""


ITALIAN_DESCRIPTION = """Rendi più sicure le tue decisioni a Skat con sessioni brevi e mirate.

Skat Trainer trasforma gli argomenti più importanti per chi inizia in domande chiare. Senza avversari, timer o account. Ogni risposta spiega cosa è giusto e perché.

QUATTRO STANZE DI ALLENAMENTO GRATUITE

CARTE E ASTE
Impara il mazzo da 32 carte, il valore delle carte, i semi, le aste, lo Skat e le basi di ogni mano.

TIPI DI GIOCO
Riconosci atout, Grand e Null. Collega le carte a un piano di gioco e pratica le regole dietro ogni scelta.

SCARTO E PRESE
Scegli due carte da scartare e allenati a rispondere al seme, usare l'atout, uscire e pianificare le prese.

SKAT+ (OPZIONALE)
Le quattro stanze di base restano gratuite. Skat+ aggiunge mani nuove, ripasso degli errori, una sfida a tempo di 90 secondi, esercizi extra e il Tavolo dei maestri.

PENSATO PER IMPARARE
Le schede da scorrere spiegano la regola sul retro. Serie, mani didattiche e feedback chiaro aiutano a ricordare quando torni al tavolo.

Skat Trainer è un'app indipendente per imparare. Le regole della casa possono variare, quindi concordatele al tavolo.

ABBONAMENTI E ACQUISTI
Skat+ offre un abbonamento mensile con rinnovo automatico a $1,99 al mese o annuale a $9,99 all'anno, entrambi con una prova gratuita di una settimana. È disponibile anche l'accesso permanente a $29,99 con acquisto singolo. Il pagamento viene addebitato sul tuo account Apple alla conferma. Gli abbonamenti si rinnovano automaticamente salvo annullamento almeno 24 ore prima della fine del periodo. Termini d'uso, EULA standard Apple: {terms_url}. Informativa sulla privacy: {privacy_url}."""


PORTUGUESE_DESCRIPTION = """Tome decisões mais seguras no Skat em sessões curtas e focadas.

Skat Trainer transforma os temas mais importantes para iniciantes em perguntas claras. Sem adversários, cronómetros nem conta. Cada resposta explica o que está certo e porquê.

QUATRO SALAS DE PRÁTICA GRATUITAS

CARTAS E LEILÃO
Aprenda o baralho de 32 cartas, o valor das cartas, os naipes, o leilão, o Skat e as bases de cada rodada.

TIPOS DE JOGO
Reconheça trunfo, Grand e Null. Relacione as cartas com um plano de jogo e pratique as regras por trás de cada decisão.

DESCARTE E VAZAS
Escolha duas cartas para descartar e pratique seguir o naipe, usar trunfo, sair e planear vazas.

SKAT+ (OPCIONAL)
As quatro salas básicas continuam gratuitas. Skat+ acrescenta mãos novas, revisão de erros, um desafio de 90 segundos, exercícios extra e a Mesa dos mestres.

FEITO PARA APRENDER
Cartões deslizáveis explicam a regra no verso. Sequências, mãos de ensino e feedback claro ajudam a lembrar quando voltar à mesa.

Skat Trainer é uma aplicação independente de aprendizagem. As regras da casa podem variar, por isso combine-as à mesa.

SUBSCRIÇÕES E COMPRAS
Skat+ está disponível numa subscrição mensal renovável automaticamente por $1,99 por mês ou anual por $9,99 por ano, ambas com um teste gratuito de uma semana. Também existe acesso permanente por $29,99 numa compra única. O pagamento é cobrado na sua conta Apple ao confirmar a compra. As subscrições renovam-se automaticamente, salvo cancelamento pelo menos 24 horas antes do fim do período. Termos de utilização, EULA padrão da Apple: {terms_url}. Política de privacidade: {privacy_url}."""


POLISH_DESCRIPTION = """Podejmuj pewniejsze decyzje w Skacie podczas krótkich, skupionych sesji.

Skat Trainer zamienia najważniejsze zagadnienia dla początkujących w jasne pytania. Bez przeciwników, zegara i konta. Każda odpowiedź wyjaśnia co jest poprawne i dlaczego.

CZTERY DARMOWE POKOJE ĆWICZEŃ

KARTY I LICYTACJA
Poznaj 32-kartową talię Skata, wartości kart, kolory, licytację, Skata i podstawy każdego rozdania.

RODZAJE GRY
Rozpoznawaj atut, Grand i Null. Dopasuj karty do planu gry i ćwicz zasady stojące za każdą decyzją.

ODKŁADANIE I LEWY
Wybierz dwie karty do odłożenia, ćwicz dokładanie do koloru, atut, wyjście i planowanie lew.

SKAT+ (OPCJONALNIE)
Cztery podstawowe pokoje pozostają bezpłatne. Skat+ dodaje nowe rozdania, powtórkę błędów, wyzwanie na 90 sekund, dodatkowe ćwiczenia i Stół mistrzów.

STWORZONE DO NAUKI
Przesuwane karty wyjaśniają zasady na odwrocie. Serie, ręce szkoleniowe i jasny feedback pomagają zapamiętać wiedzę przy stole.

Skat Trainer to niezależna aplikacja edukacyjna. Zasady domowe mogą się różnić, dlatego ustalcie je przy stole.

SUBSKRYPCJE I ZAKUPY
Skat+ oferuje automatycznie odnawianą subskrypcję miesięczną za 1,99 $ lub roczną za 9,99 $, obie z tygodniowym bezpłatnym okresem próbnym. Stały dostęp kosztuje 29,99 $ w jednorazowym zakupie. Płatność jest pobierana z konta Apple po potwierdzeniu. Warunki, standardowa umowa Apple: {terms_url}. Polityka prywatności: {privacy_url}."""


SCANDINAVIAN_DESCRIPTION = """Lär dig Skat med korta och fokuserade övningar.

Skat Trainer gör de viktigaste ämnena för nybörjare till tydliga frågor. Inga motståndare, tidtagning eller konto. Varje svar förklarar både vad som är rätt och varför.

FYRA GRATIS ÖVNINGSRUM

KORT OCH BUD
Lär dig Skats 32-kortslek, kortvärden, färger, budgivning, Skat och grunderna i varje giv.

SPELTYPER
Känn igen trumf, Grand och Null. Koppla korten till en spelplan och öva reglerna bakom varje beslut.

KASTA OCH STICK
Välj två kort att kasta och öva på att följa färg, trumf, utspel och planering av stick.

SKAT+ (VALFRITT)
De fyra grundrummen är gratis. Skat+ lägger till nya händer, repetition av misstag, en 90-sekundersutmaning, extra övningar och Mästarbordet.

GJORD FÖR LÄRANDE
Svepbara coachkort förklarar regeln på baksidan. Serier, lärohänder och tydlig feedback hjälper dig att minnas vid bordet.

Skat Trainer är en fristående inlärningsapp. Husregler kan skilja sig, så kom överens vid bordet.

PRENUMERATIONER OCH KÖP
Skat+ finns som automatiskt förnyande månadsprenumeration för $1,99 per månad eller årsabonnemang för $9,99 per år, båda med en veckas gratis provperiod. Permanent tillgång kostar $29,99 som engångsköp. Betalningen debiteras ditt Apple-konto vid bekräftelse. Prenumerationer förnyas automatiskt om de inte avslutas minst 24 timmar före periodens slut. Villkor, Apples standard-EULA: {terms_url}. Integritetspolicy: {privacy_url}."""


FINNISH_DESCRIPTION = """Harjoittele Skatia lyhyissä ja keskittyneissä tuokioissa.

Skat Trainer muuttaa aloittelijan tärkeimmät aiheet selkeiksi harjoituskysymyksiksi. Ei vastustajia, ajastinta tai tiliä. Jokainen vastaus kertoo sekä mikä on oikein että miksi.

NELJÄ ILMAISTA HARJOITUSHUONETTA

KORTIT JA TARJOAMINEN
Opettele 32 kortin Skat-pakka, korttien arvot, maat, tarjoaminen, Skat ja jokaisen jaon perusteet.

PELITYYPIT
Tunnista valtti, Grand ja Null. Yhdistä kortit pelisuunnitelmaan ja harjoittele päätösten taustalla olevia sääntöjä.

POISLAITTO JA TIKIT
Valitse kaksi korttia pois ja harjoittele maahan tunnustamista, valttia, lähtöä ja tikkien suunnittelua.

SKAT+ (VALINNAINEN)
Neljä perushuonetta ovat ilmaisia. Skat+ lisää uusia käsiä, virheiden kertaamisen, 90 sekunnin haasteen, lisäharjoituksia ja Mestaripöydän.

TEHTY OPPIMISTA VARTEN
Pyyhkäistävät kortit selittävät säännön takapuolella. Sarjat, opetusjaot ja selkeä palaute auttavat muistamaan opit pöydässä.

Skat Trainer on itsenäinen oppimissovellus. Kotisäännöt voivat vaihdella, joten sopikaa säännöistä pöydässä.

TILAUKSET JA OSTOT
Skat+ on saatavilla automaattisesti uusiutuvana kuukausitilauksena hintaan 1,99 $ tai vuositilauksena hintaan 9,99 $. Molempiin kuuluu viikon ilmainen kokeilu. Pysyvä käyttöoikeus maksaa 29,99 $ kertaostoksena. Tilaus uusiutuu automaattisesti, ellei sitä peruta vähintään 24 tuntia ennen jakson päättymistä. Käyttöehdot, Applen vakio-EULA: {terms_url}. Tietosuojakäytäntö: {privacy_url}."""


CENTRAL_EUROPEAN_DESCRIPTION = """Získejte jistotu ve Skatu během krátkých a soustředěných lekcí.

Skat Trainer mění nejdůležitější témata pro začátečníky na jasné cvičné otázky. Bez soupeřů, časovače a účtu. Každá odpověď vysvětlí co je správně a proč.

ČTYŘI BEZPLATNÉ TRÉNINKOVÉ MÍSTNOSTI

KARTY A LICITACE
Poznejte 32karetní balíček Skatu, hodnoty karet, barvy, licitaci, Skat a základy každého rozdání.

TYPY HRY
Rozpoznávejte trumf, Grand a Null. Propojte karty s herním plánem a procvičujte pravidla za každým rozhodnutím.

ODKLÁDÁNÍ A ŠTYCHY
Vyberte dvě karty k odložení a procvičujte povinnost přiznat barvu, trumf, výnos a plánování štychů.

SKAT+ (VOLITELNÉ)
Čtyři základní místnosti zůstávají zdarma. Skat+ přidává nové hry, opakování chyb, 90sekundovou výzvu, další cvičení a Mistrovský stůl.

VYTVOŘENO PRO UČENÍ
Karty s posunutím vysvětlují pravidlo na zadní straně. Série, výukové hry a jasná zpětná vazba pomáhají zapamatovat si vše u stolu.

Skat Trainer je nezávislá výuková aplikace. Domácí pravidla se mohou lišit, proto se na nich u stolu dohodněte.

PŘEDPLATNÉ A NÁKUPY
Skat+ nabízí měsíční předplatné za 1,99 $ nebo roční za 9,99 $, obě s týdenní bezplatnou zkouškou. Trvalý přístup stojí 29,99 $ jako jednorázový nákup. Předplatné se obnovuje automaticky, pokud jej nezrušíte alespoň 24 hodin před koncem období. Podmínky, standardní EULA Apple: {terms_url}. Zásady ochrany soukromí: {privacy_url}."""


RUSSIAN_DESCRIPTION = """Уверенно играйте в Скат, занимаясь короткими целенаправленными сессиями.

Skat Trainer превращает самые важные темы для начинающих в понятные вопросы. Без соперников, таймера и регистрации. Каждый ответ объясняет правильный выбор и его причину.

ЧЕТЫРЕ БЕСПЛАТНЫЕ КОМНАТЫ

КАРТЫ И ТОРГИ
Изучайте колоду из 32 карт, ценность карт, масти, торги, прикуп и основы каждой раздачи.

ВИДЫ ИГРЫ
Распознавайте козырь, Grand и Null. Связывайте карты с планом игры и тренируйте правила решений.

СНОС И ВЗЯТКИ
Выбирайте две карты для сноса и тренируйте обязательный ответ в масть, козырь, первый ход и планирование взяток.

SKAT+ (НЕОБЯЗАТЕЛЬНО)
Четыре базовые комнаты остаются бесплатными. Skat+ добавляет новые руки, повторение ошибок, испытание на 90 секунд, дополнительные задания и Стол мастеров.

СОЗДАНО ДЛЯ ОБУЧЕНИЯ
Карточки смахиванием объясняют правило на обороте. Серии, учебные раздачи и понятная обратная связь помогают запомнить материал за столом.

Skat Trainer это независимое учебное приложение. Домашние правила могут отличаться, поэтому договоритесь о них за столом.

ПОДПИСКИ И ПОКУПКИ
Skat+ доступен по автоматически продлеваемой подписке: $1,99 в месяц или $9,99 в год, каждая включает бесплатную пробную неделю. Постоянный доступ можно купить разово за $29,99. Подписка продлевается автоматически, если её не отменить минимум за 24 часа до конца периода. Условия, стандартная EULA Apple: {terms_url}. Политика конфиденциальности: {privacy_url}."""


TURKISH_DESCRIPTION = """Kısa ve odaklı oturumlarla Skat kararlarında ustalaşın.

Skat Trainer, yeni başlayanların en çok ihtiyaç duyduğu konuları anlaşılır alıştırma sorularına dönüştürür. Rakip, sayaç veya hesap gerekmez. Her yanıt neyin doğru olduğunu ve nedenini açıklar.

DÖRT ÜCRETSİZ ALIŞTIRMA ODASI

KARTLAR VE İHALE
32 kartlık Skat destesini, kart değerlerini, renkleri, ihaleyi, Skat'ı ve her elin temellerini öğrenin.

OYUN TÜRLERİ
Kozu, Grand ve Null'ı tanıyın. Kartları oyun planıyla ilişkilendirin ve kararların arkasındaki kuralları çalışın.

KART ATMA VE EL ALMA
Atmak için iki kart seçin, renk takip etmeyi, kozu, çıkışı ve el planlamasını çalışın.

SKAT+ (İSTEĞE BAĞLI)
Dört temel oda ücretsiz kalır. Skat+ yeni eller, hataları tekrar etme, 90 saniyelik meydan okuma, ek alıştırmalar ve Ustalar Masası ekler.

ÖĞRENMEK İÇİN TASARLANDI
Kaydırılabilir koçluk kartları kuralı arka yüzünde açıklar. Seriler, öğretici eller ve net geri bildirim masa başında hatırlamayı kolaylaştırır.

Skat Trainer bağımsız bir öğrenme uygulamasıdır. Ev kuralları değişebilir, bu yüzden masada ortak kuralları belirleyin.

ABONELİKLER VE SATIN ALMALAR
Skat+, ayda $1,99 veya yılda $9,99 karşılığında otomatik yenilenen abonelik olarak sunulur. İkisinde de bir haftalık ücretsiz deneme vardır. Kalıcı erişim $29,99 tek seferlik satın almadır. Abonelik dönem bitmeden en az 24 saat önce iptal edilmezse yenilenir. Kullanım koşulları, Apple standart EULA: {terms_url}. Gizlilik politikası: {privacy_url}."""


ASIAN_DESCRIPTION = """짧고 집중력 있는 세션으로 Skat의 판단력을 키워 보세요.

Skat Trainer는 초보자에게 가장 필요한 내용을 명확한 연습 문제로 바꿔 줍니다. 상대방, 타이머, 계정이 필요 없습니다. 모든 답변은 무엇이 맞는지뿐 아니라 그 이유도 설명합니다.

무료 연습실 네 곳

카드와 입찰
32장 Skat 덱, 카드 가치, 무늬, 입찰, Skat과 각 라운드의 기본을 배웁니다.

게임 종류와 카드 버리기
트럼프, Grand, Null을 구분하고 열두 장 중 두 장을 선택해 트레이너의 설명과 비교합니다.

트릭 플레이
무늬 따라내기, 트럼프, 첫 카드와 트릭 계획을 연습합니다.

Skat+ 선택 사항
기본 연습실 네 곳은 계속 무료입니다. 새 핸드, 오답 복습, 90초 도전, 추가 문제와 마스터 테이블을 제공합니다.

구독 및 구입
월 $1.99 또는 연 $9.99의 자동 갱신 구독, 두 상품 모두 1주 무료 체험, 또는 $29.99 일회성 영구 이용권을 이용할 수 있습니다. 구독은 기간 종료 24시간 전까지 취소하지 않으면 갱신됩니다. 이용 약관, Apple 표준 EULA: {terms_url}. 개인정보 처리방침: {privacy_url}."""


JAPANESE_DESCRIPTION = """短時間で集中して、シュカートの判断力を身につけましょう。

Skat Trainerは、初心者に必要な内容を分かりやすい練習問題にします。対戦相手もタイマーもアカウントも不要です。正解だけでなく、その理由も説明します。

無料の練習ルーム4室

32枚のシュカートのカード、カードの価値、スート、ビッド、スカートと各ラウンドの基本を学びます。トランプ、グランド、ヌルを見分け、12枚から2枚を選び、トリックの計画を練習できます。

Skat+では新しいハンド、間違いの復習、90秒チャレンジ、追加問題、マスターテーブルを利用できます。基本の4室は無料のままです。

スワイプできるカードの裏面でルールを説明します。ハウスルールは異なる場合があるため、テーブルで確認してください。

Skat+は月額1.99ドルまたは年額9.99ドルの自動更新サブスクリプションで利用でき、どちらも1週間の無料トライアル付きです。永久アクセスは29.99ドルの買い切りです。利用規約: {terms_url}。プライバシーポリシー: {privacy_url}."""


CHINESE_DESCRIPTION = """用短時、專注的練習提升你在Skat中的判斷力。

Skat Trainer把初學者最需要掌握的內容變成清晰的練習題。不需要對手、計時器或帳號。每個答案都會說明什麼是正確的，以及為什麼。

四個免費練習室

學習32張Skat牌、牌面價值、花色、叫牌、底牌以及每一局的基礎。識別主牌、Grand和Null，選擇兩張墊牌，並練習跟牌、首攻和墩牌計畫。

Skat+增加全新牌局、錯題重練、90秒挑戰、額外練習和大師桌。四個基礎練習室始終免費。

可滑動的教練卡片會在背面解說規則。地方規則可能不同，請在牌桌上先確認共同規則。

Skat+提供自動續訂的每月訂閱，每月1.99美元，或每年9.99美元的年度訂閱，兩者均含一週免費試用。永久存取權為29.99美元一次購買。除非在目前週期結束前至少24小時取消，否則訂閱會自動續訂。使用條款，Apple標準EULA：{terms_url}。隱私權政策：{privacy_url}."""


ARABIC_DESCRIPTION = """طوّر قراراتك في لعبة سكات من خلال جلسات قصيرة ومركّزة.

يحوّل Skat Trainer أهم ما يحتاجه المبتدئون إلى أسئلة تدريب واضحة. لا خصوم ولا مؤقت ولا حساب. يشرح كل جواب ما هو صحيح ولماذا.

أربع غرف تدريب مجانية

تعلّم مجموعة سكات المكوّنة من 32 بطاقة، وقيم البطاقات، والأنواع، والمزايدة، والسكّات وأساسيات كل جولة. تعرّف إلى الحكم وGrand وNull، واختر بطاقتين للتخلّص منهما وتدرّب على لعب اللمّات.

تبقى غرف الأساس الأربع مجانية. يضيف Skat+ أيادي جديدة، ومراجعة الأخطاء، وتحدي 90 ثانية، وتمارين إضافية وطاولة الأساتذة.

تشرح بطاقات التدريب القابلة للسحب القاعدة على ظهرها. قد تختلف قواعد المنزل، لذلك اتفقوا على القواعد عند الطاولة.

يتوفر Skat+ باشتراك شهري يتجدد تلقائياً بقيمة 1.99 دولار أو سنوي بقيمة 9.99 دولار، وكلاهما يتضمن تجربة مجانية لمدة أسبوع. يتوفر وصول دائم مقابل 29.99 دولاراً. يتجدد الاشتراك تلقائياً ما لم تلغه قبل 24 ساعة على الأقل من نهاية الفترة. شروط الاستخدام: {terms_url}. سياسة الخصوصية: {privacy_url}."""


HEBREW_DESCRIPTION = """למדו לשחק סקאט בביטחון במפגשים קצרים וממוקדים.

Skat Trainer הופך את הנושאים החשובים למתחילים לשאלות תרגול ברורות. בלי יריבים, בלי שעון ובלי חשבון. כל תשובה מסבירה גם מה נכון וגם למה.

ארבעה חדרי תרגול בחינם

למדו את חפיסת הסקאט בת 32 הקלפים, ערכי הקלפים, הסדרות, ההכרזה, הסקאט ואת יסודות כל סיבוב. תרגלו טראמפ, Grand, Null, זריקת שתי קלפים ומשחק לקיחות.

ארבעת חדרי היסוד נשארים בחינם. Skat+ מוסיף ידיים חדשות, חזרה על טעויות, אתגר של 90 שניות, תרגילים נוספים ושולחן המאסטר.

כרטיסי אימון בהחלקה מסבירים את הכלל בגב הכרטיס. כללי הבית עשויים להשתנות, לכן הסכימו עליהם ליד השולחן.

Skat+ זמין במנוי חודשי ב-$1.99 או שנתי ב-$9.99, ושניהם כוללים ניסיון חינם של שבוע. גישה קבועה זמינה ברכישה חד-פעמית ב-$29.99. המנוי מתחדש אוטומטית אלא אם מבטלים לפחות 24 שעות לפני סוף התקופה. תנאי שימוש: {terms_url}. מדיניות פרטיות: {privacy_url}."""


CATALAN_DESCRIPTION = """Millora les teves decisions de Skat en sessions curtes i enfocades.

Skat Trainer converteix els temes més importants per a principiants en preguntes clares. Sense rivals, temporitzador ni compte. Cada resposta explica què és correcte i per què.

Aprèn la baralla de 32 cartes, els valors, els pals, la subhasta, l'Skat i les bases de cada ronda. Reconeix el triomf, el Grand i el Null, tria dues cartes per descartar i practica seguir el pal, la sortida i les bazes.

Les quatre sales bàsiques continuen sent gratuïtes. Skat+ afegeix mans noves, repàs d'errors, un repte de 90 segons, exercicis extra i la Taula dels mestres. Les targetes lliscables expliquen la regla al darrere.

Les regles de casa poden variar, així que acordeu-les a la taula. Skat+ ofereix una subscripció mensual de renovació automàtica per 1,99 $ o anual per 9,99 $, ambdues amb una prova gratuïta d'una setmana. L'accés permanent costa 29,99 $. Condicions: {terms_url}. Privadesa: {privacy_url}."""


INDONESIAN_DESCRIPTION = """Latih keputusan Skat dengan sesi singkat dan terarah.

Skat Trainer mengubah hal-hal penting bagi pemula menjadi pertanyaan latihan yang jelas. Tanpa lawan, timer, atau akun. Setiap jawaban menjelaskan apa yang benar dan alasannya.

Pelajari dek Skat 32 kartu, nilai kartu, jenis kartu, tawaran, Skat, dan dasar setiap ronde. Kenali trump, Grand, dan Null, pilih dua kartu untuk dibuang, lalu latih mengikuti jenis kartu, pembukaan, dan trik.

Empat ruang dasar tetap gratis. Skat+ menambahkan tangan baru, latihan ulang kesalahan, tantangan 90 detik, latihan tambahan, dan Meja Master. Kartu pelatihan menjelaskan aturan di bagian belakang.

Aturan rumah dapat berbeda, jadi sepakati aturan di meja. Skat+ tersedia sebagai langganan bulanan $1,99 atau tahunan $9,99 yang diperpanjang otomatis, masing-masing dengan uji coba gratis satu minggu. Akses permanen seharga $29,99. Ketentuan: {terms_url}. Privasi: {privacy_url}."""


MALAY_DESCRIPTION = """Tingkatkan keputusan Skat anda melalui sesi ringkas dan fokus.

Skat Trainer menukar topik paling penting untuk pemula menjadi soalan latihan yang jelas. Tiada lawan, pemasa atau akaun. Setiap jawapan menerangkan perkara yang betul dan sebabnya.

Pelajari dek 32 kad Skat, nilai kad, warna, bidaan, Skat dan asas setiap pusingan. Kenal pasti trump, Grand dan Null, pilih dua kad untuk dibuang serta berlatih mengikut warna, pembukaan dan trik.

Empat bilik asas kekal percuma. Skat+ menambah tangan baharu, ulang kaji kesilapan, cabaran 90 saat, latihan tambahan dan Meja Master. Kad bimbingan menerangkan peraturan di bahagian belakang.

Peraturan rumah mungkin berbeza, jadi persetujuilah peraturan di meja. Skat+ tersedia sebagai langganan bulanan $1.99 atau tahunan $9.99 yang diperbaharui automatik, dengan percubaan percuma seminggu. Akses kekal berharga $29.99. Syarat: {terms_url}. Privasi: {privacy_url}."""


VIETNAMESE_DESCRIPTION = """Rèn luyện quyết định chơi Skat qua những buổi học ngắn và tập trung.

Skat Trainer biến những nội dung quan trọng nhất cho người mới thành các câu hỏi luyện tập rõ ràng. Không có đối thủ, đồng hồ hay tài khoản. Mỗi câu trả lời giải thích cả điều đúng lẫn lý do.

Học bộ bài Skat 32 lá, giá trị lá bài, chất, đấu giá, Skat và nền tảng của mỗi ván. Nhận biết chủ, Grand và Null, chọn hai lá để bỏ, rồi luyện theo chất, lượt ra bài và các lần.

Bốn phòng cơ bản vẫn miễn phí. Skat+ thêm những bộ bài mới, ôn lại lỗi sai, thử thách 90 giây, bài tập bổ sung và Bàn cao thủ. Thẻ huấn luyện giải thích luật ở mặt sau.

Luật địa phương có thể khác nhau, vì vậy hãy thống nhất luật tại bàn. Skat+ có gói tháng $1,99 hoặc gói năm $9,99 tự động gia hạn, cả hai có một tuần dùng thử miễn phí. Quyền truy cập vĩnh viễn giá $29,99. Điều khoản: {terms_url}. Quyền riêng tư: {privacy_url}."""


THAI_DESCRIPTION = """ฝึกตัดสินใจเล่นสกัตด้วยบทเรียนสั้น ๆ ที่เน้นประเด็นสำคัญ

Skat Trainer เปลี่ยนหัวข้อที่ผู้เริ่มต้นต้องรู้ให้เป็นคำถามฝึกที่เข้าใจง่าย ไม่ต้องมีคู่แข่ง ตัวจับเวลา หรือบัญชี ทุกคำตอบอธิบายทั้งสิ่งที่ถูกและเหตุผล

เรียนรู้สำรับสกัต 32 ใบ ค่าไพ่ ดอกไพ่ การประมูล ไพ่ Skat และพื้นฐานของแต่ละรอบ แยกแยะทรัมป์ Grand และ Null เลือกไพ่สองใบเพื่อทิ้ง และฝึกการเล่นทริก

ห้องพื้นฐานทั้ง 4 ห้องยังคงใช้ฟรี Skat+ เพิ่มมือไพ่ใหม่ การทบทวนข้อผิดพลาด ความท้าทาย 90 วินาที แบบฝึกเพิ่มเติม และโต๊ะมาสเตอร์ การ์ดโค้ชอธิบายกฎด้านหลัง

กติกาอาจต่างกัน จึงควรตกลงกติกาที่โต๊ะ Skat+ มีสมาชิกแบบรายเดือน $1.99 หรือรายปี $9.99 ต่ออายุอัตโนมัติ ทั้งสองแบบมีทดลองใช้ฟรีหนึ่งสัปดาห์ สิทธิ์ถาวรซื้อครั้งเดียว $29.99 ข้อกำหนด: {terms_url} นโยบายความเป็นส่วนตัว: {privacy_url}"""


GREEK_DESCRIPTION = """Μάθετε Σκατ με σύντομες και στοχευμένες προπονήσεις.

Το Skat Trainer μετατρέπει τα πιο σημαντικά θέματα για αρχάριους σε σαφείς ερωτήσεις εξάσκησης. Χωρίς αντιπάλους, χρονόμετρο ή λογαριασμό. Κάθε απάντηση εξηγεί τι είναι σωστό και γιατί.

Μάθετε την τράπουλα 32 φύλλων, τις αξίες, τα χρώματα, την πλειοδοσία, το Skat και τα βασικά κάθε γύρου. Αναγνωρίστε ατού, Grand και Null, επιλέξτε δύο φύλλα για απόρριψη και εξασκηθείτε στις λεβέ.

Οι τέσσερις βασικές αίθουσες παραμένουν δωρεάν. Το Skat+ προσθέτει νέες διανομές, επανάληψη λαθών, πρόκληση 90 δευτερολέπτων, επιπλέον ασκήσεις και το Τραπέζι των Μαστέρ. Οι κάρτες προπόνησης εξηγούν τους κανόνες στο πίσω μέρος.

Οι κανόνες μπορεί να διαφέρουν, οπότε συμφωνήστε τους στο τραπέζι. Το Skat+ προσφέρεται με αυτόματη συνδρομή $1,99 τον μήνα ή $9,99 τον χρόνο, με δοκιμή μίας εβδομάδας. Η μόνιμη πρόσβαση κοστίζει $29,99. Όροι: {terms_url}. Απόρρητο: {privacy_url}."""


CROATIAN_DESCRIPTION = """Naučite Skat kroz kratke i usmjerene vježbe.

Skat Trainer pretvara najvažnije teme za početnike u jasna pitanja. Bez protivnika, mjerača vremena ili računa. Svaki odgovor objašnjava što je ispravno i zašto.

Upoznajte špil od 32 karte, vrijednosti, boje, licitaciju, Skat i osnove svake ruke. Prepoznajte adut, Grand i Null, odaberite dvije karte za odlaganje te vježbajte praćenje boje, izlaz i štihove.

Četiri osnovne sobe ostaju besplatne. Skat+ dodaje nove ruke, ponavljanje pogrešaka, izazov od 90 sekundi, dodatne vježbe i Stol majstora. Kartice za treniranje objašnjavaju pravilo na poleđini.

Kućna pravila mogu se razlikovati, stoga ih dogovorite za stolom. Skat+ nudi mjesečnu pretplatu od 1,99 $ ili godišnju od 9,99 $, obje s besplatnim probnim tjednom. Trajni pristup stoji 29,99 $. Uvjeti: {terms_url}. Privatnost: {privacy_url}."""


SLOVENIAN_DESCRIPTION = """Učite Skat s kratkimi in zbranimi vajami.

Skat Trainer najpomembnejše teme za začetnike spremeni v jasna vprašanja. Brez nasprotnikov, merilnika časa ali računa. Vsak odgovor pojasni, kaj je pravilno in zakaj.

Spoznajte 32-kartni komplet, vrednosti kart, barve, licitiranje, Skat in osnove vsake igre. Prepoznajte adut, Grand in Null, izberite dve karti za odlaganje ter vadite sledenje barvi, izhod in štihe.

Štiri osnovne sobe ostanejo brezplačne. Skat+ doda nove roke, ponavljanje napak, 90-sekundni izziv, dodatne vaje in Mizo mojstrov. Karte za učenje pojasnijo pravilo na zadnji strani.

Hišna pravila se lahko razlikujejo, zato se o njih dogovorite za mizo. Skat+ ponuja mesečno naročnino 1,99 $ ali letno 9,99 $, obe z brezplačnim tedenskim preizkusom. Trajni dostop stane 29,99 $. Pogoji: {terms_url}. Zasebnost: {privacy_url}."""


CHINESE_SIMPLIFIED_DESCRIPTION = """用短时、专注的练习，提升你在Skat中的判断力。

Skat Trainer把初学者最需要掌握的内容变成清晰的练习题。不需要对手、计时器或账号。每个答案都会说明什么是正确的，以及为什么。

学习32张Skat牌、牌面价值、花色、叫牌、底牌以及每一局的基础。识别主牌、Grand和Null，选择两张垫牌，并练习跟牌、首攻和墩牌计划。

四个基础练习室始终免费。Skat+增加全新牌局、错题重练、90秒挑战、额外练习和大师桌。可滑动的教练卡片会在背面解释规则。

地方规则可能不同，请在牌桌上先确认共同规则。Skat+提供自动续订的月度订阅，每月1.99美元，或年度订阅，每年9.99美元，两者均含一周免费试用。永久访问权为29.99美元一次购买。使用条款：{terms_url}。隐私政策：{privacy_url}."""


DESCRIPTIONS = {
    "de": GERMAN_DESCRIPTION,
    "en": ENGLISH_DESCRIPTION,
    "en-GB": ENGLISH_DESCRIPTION,
    "fr": FRENCH_DESCRIPTION,
    "es": SPANISH_DESCRIPTION,
    "it": ITALIAN_DESCRIPTION,
    "pt": PORTUGUESE_DESCRIPTION,
    "pl": POLISH_DESCRIPTION,
    "da": SCANDINAVIAN_DESCRIPTION,
    "sv": SCANDINAVIAN_DESCRIPTION,
    "no": SCANDINAVIAN_DESCRIPTION,
    "fi": FINNISH_DESCRIPTION,
    "cs": CENTRAL_EUROPEAN_DESCRIPTION,
    "sk": CENTRAL_EUROPEAN_DESCRIPTION,
    "hu": CENTRAL_EUROPEAN_DESCRIPTION,
    "ro": CENTRAL_EUROPEAN_DESCRIPTION,
    "ru": RUSSIAN_DESCRIPTION,
    "uk": RUSSIAN_DESCRIPTION,
    "tr": TURKISH_DESCRIPTION,
    "el": GREEK_DESCRIPTION,
    "hr": CROATIAN_DESCRIPTION,
    "sl": SLOVENIAN_DESCRIPTION,
    "ca": CATALAN_DESCRIPTION,
    "id": INDONESIAN_DESCRIPTION,
    "ms": MALAY_DESCRIPTION,
    "vi": VIETNAMESE_DESCRIPTION,
    "th": THAI_DESCRIPTION,
    "ja": JAPANESE_DESCRIPTION,
    "ko": ASIAN_DESCRIPTION,
    "zh-Hans": CHINESE_SIMPLIFIED_DESCRIPTION,
    "zh-Hant": CHINESE_DESCRIPTION,
    "ar": ARABIC_DESCRIPTION,
    "he": HEBREW_DESCRIPTION,
}


def localized(
    name: str,
    subtitle: str,
    keywords: str,
    promo: str,
    release: str,
    language: str,
) -> dict[str, str]:
    return text(name, subtitle, keywords, promo, release, DESCRIPTIONS.get(language, ENGLISH_DESCRIPTION))


DATA = {
    "de": localized(
        "Skat Trainer: Skat üben",
        "Skat lernen, Runde für Runde",
        "skat,lernen,üben,karten,reizen,trumpf,grand,null,drücken,stich,quiz,strategie,regeln",
        "Neu: Endlos üben mit frischen Händen, Fehler wiederholen nach Plan und 90 Sekunden für deine Bestleistung.",
        "Üben ohne Ende.\n\nEndlos üben erzeugt neue Skat-Hände. Fehler wiederholen bringt verpasste Fragen nach einem Lernplan zurück.",
        "de",
    ),
    "en": localized(
        "Skat Trainer: Learn Skat",
        "Learn Skat, Hand by Hand",
        "skat,cards,german card game,learn,bidding,trump,grand,null,discard,tricks,quiz,strategy,rules",
        "Learn Skat with fresh hands, mistake review, a 90-second challenge, and clear coaching for every decision.",
        "Welcome to Skat Trainer. Practise cards, bidding, game types, discarding, and trick play in four free rooms.",
        "en",
    ),
    "en-GB": localized(
        "Skat Trainer: Learn Skat",
        "Learn Skat, Hand by Hand",
        "skat,cards,german card game,learn,bidding,trump,grand,null,discard,tricks,quiz,strategy,rules",
        "Learn Skat with fresh hands, mistake review, a 90-second challenge, and clear coaching for every decision.",
        "Welcome to Skat Trainer. Practise cards, bidding, game types, discarding, and trick play in four free rooms.",
        "en-GB",
    ),
    "fr": localized(
        "Skat Trainer: Apprendre Skat",
        "Skat, cartes et décisions",
        "skat,cartes,jeu allemand,apprendre,enchères,atout,grand,null,écart,plis,quiz,stratégie,règles",
        "Apprenez le Skat avec de nouvelles mains, la reprise des erreurs et un défi de 90 secondes.",
        "Bienvenue dans Skat Trainer. Entraînez-vous aux cartes, enchères, types de jeu, écarts et plis.",
        "fr",
    ),
    "es": localized(
        "Skat Trainer: Aprende Skat",
        "Aprende Skat, mano a mano",
        "skat,cartas,juego alemán,aprender,subasta,triunfo,grand,null,descarte,bazas,quiz,estrategia",
        "Aprende Skat con manos nuevas, repaso de errores y un reto de 90 segundos con explicaciones claras.",
        "Bienvenido a Skat Trainer. Practica cartas, subastas, tipos de juego, descartes y bazas.",
        "es",
    ),
    "it": localized(
        "Skat Trainer: Impara Skat",
        "Skat, carte e decisioni",
        "skat,carte,gioco tedesco,imparare,aste,atout,grand,null,scarto,prese,quiz,strategia,regole",
        "Impara lo Skat con mani nuove, ripasso degli errori e una sfida a tempo di 90 secondi.",
        "Benvenuto in Skat Trainer. Allenati con carte, aste, tipi di gioco, scarto e prese.",
        "it",
    ),
    "pt": localized(
        "Skat Trainer: Aprenda Skat",
        "Aprenda Skat, mão a mão",
        "skat,cartas,jogo alemão,aprender,leilão,trunfo,grand,null,descarte,vazas,quiz,estratégia,regras",
        "Aprenda Skat com mãos novas, revisão de erros e um desafio de 90 segundos com explicações claras.",
        "Bem-vindo ao Skat Trainer. Pratique cartas, leilão, tipos de jogo, descarte e vazas.",
        "pt",
    ),
    "pl": localized(
        "Skat Trainer: Nauka Skata",
        "Skat, nauka krok po kroku",
        "skat,karty,german gra,nauka,licytacja,atut,grand,null,odkładanie,lewy,quiz,strategia,zasady",
        "Ucz się Skata na nowych rozdaniach, powtarzaj błędy i podejmij wyzwanie 90 sekund.",
        "Witaj w Skat Trainer. Ćwicz karty, licytację, rodzaje gry, odkładanie i lewy.",
        "pl",
    ),
    "nl": localized(
        "Skat Trainer: Skat leren",
        "Leer Skat, hand voor hand",
        "skat,kaarten,duits kaartspel,leren,bieden,troef,grand,null,afleggen,slagen,quiz,strategie,regels",
        "Leer Skat met nieuwe handen, fouten opnieuw oefenen en een uitdaging van 90 seconden.",
        "Welkom bij Skat Trainer. Oefen kaarten, bieden, spelvarianten, afleggen en slagenspel.",
        "nl",
    ),
    "da": localized(
        "Skat Trainer: Lær at spille",
        "Lær Skat, hånd for hånd",
        "skat,kort,tysk kortspil,lær,bud,trumf,grand,null,udspil,stik,quiz,strategi,regler",
        "Lær Skat med nye hænder, gentag fejl og en 90-sekunders udfordring.",
        "Velkommen til Skat Trainer. Øv kort, melding, spilformer, udspil og stik.",
        "da",
    ),
    "sv": localized(
        "Skat Trainer: Lär dig Skat",
        "Lär dig Skat, hand för hand",
        "skat,kort,tyskt kortspel,lär,bud,trumf,grand,null,utspel,stick,quiz,strategi,regler",
        "Lär dig Skat med nya händer, felgenomgång och en 90-sekunders utmaning.",
        "Välkommen till Skat Trainer. Öva kort, budgivning, spelformer, utspel och stick.",
        "sv",
    ),
    "no": localized(
        "Skat Trainer: Lær å spille",
        "Lær Skat, hånd for hånd",
        "skat,kort,tysk kortspill,lær,bud,trumf,grand,null,utspill,stikk,quiz,strategi,regler",
        "Lær Skat med nye hender, gjennomgang av feil og en 90-sekunders utfordring.",
        "Velkommen til Skat Trainer. Øv på kort, melding, spilltyper, utspill og stikk.",
        "no",
    ),
    "fi": localized(
        "Skat Trainer: Opi Skatia",
        "Opi Skat, käsi kerrallaan",
        "skat,kortit,saksalainen peli,opi,tarjous,valtti,grand,null,poisheitto,tikit,visa,säännöt",
        "Opi Skatia uusilla käsillä, kertaa virheet ja haasta itsesi 90 sekunnin harjoituksessa.",
        "Tervetuloa Skat Traineriin. Harjoittele kortteja, tarjoamista, pelityyppejä ja tikkejä.",
        "fi",
    ),
    "cs": localized(
        "Skat Trainer: Nauč se Skat",
        "Skat, uč se hru po ruce",
        "skat,karty,německá hra,učení,licitace,trumf,grand,null,odklad,štychy,kvíz,strategie,pravidla",
        "Naučte se Skat s novými hrami, opakováním chyb a 90sekundovou výzvou.",
        "Vítejte ve Skat Traineru. Procvičujte karty, licitaci, typy hry, odkládání a štychy.",
        "cs",
    ),
    "sk": localized(
        "Skat Trainer: Nauč sa Skat",
        "Skat, uč sa kolo za kolom",
        "skat,karty,nemecká hra,učenie,licitácia,tromf,grand,null,odkladanie,štychy,kvíz,pravidlá",
        "Nauč sa Skat s novými hrami, opakovaním chýb a 90-sekundovou výzvou.",
        "Vitaj v Skat Traineri. Precvičuj karty, licitáciu, typy hry, odkladanie a štychy.",
        "sk",
    ),
    "hu": localized(
        "Skat Trainer: Tanulj Skatot",
        "Skat, leosztásról leosztásra",
        "skat,kártya,német kártyajáték,tanulás,licit,adu,grand,null,dobás,ütés,kvíz",
        "Tanulj Skatot új leosztásokkal, hibaismétléssel és 90 másodperces kihívással.",
        "Üdvözöl a Skat Trainer. Gyakorold a kártyákat, licitet, játéktípusokat, dobást és ütéseket.",
        "hu",
    ),
    "ro": localized(
        "Skat Trainer: Învață Skat",
        "Skat, învață mână cu mână",
        "skat,cărți,joc german,învățare,licitație,atu,grand,null,decartare,levate,quiz,strategie",
        "Învață Skat cu mâini noi, repetarea greșelilor și o provocare de 90 de secunde.",
        "Bine ai venit la Skat Trainer. Exersează cărți, licitație, tipuri de joc, decartare și levate.",
        "ro",
    ),
    "ru": localized(
        "Skat Trainer: Учимся в Скат",
        "Скат: учись шаг за шагом",
        "скат,карты,обучение,торги,козырь,взятки",
        "Учитесь играть в Скат на новых раздачах, повторяйте ошибки и проходите испытание 90 секунд.",
        "Добро пожаловать в Skat Trainer. Тренируйте карты, торги, виды игры, снос и взятки.",
        "ru",
    ),
    "uk": localized(
        "Skat Trainer: Вивчай Скат",
        "Скат: вчися крок за кроком",
        "скат,карти,навчання,торги,козир,взятки",
        "Вивчайте Скат на нових роздачах, повторюйте помилки та проходьте 90-секундний виклик.",
        "Ласкаво просимо до Skat Trainer. Тренуйте карти, торги, види гри, знос і взятки.",
        "uk",
    ),
    "tr": localized(
        "Skat Trainer: Skat Öğren",
        "Skat öğren, el el ilerle",
        "skat,kartlar,alman kart oyunu,öğrenme,ihale,koz,grand,null,kart atma,el,quiz,strateji,kurallar",
        "Yeni eller, hata tekrarı ve 90 saniyelik meydan okumayla Skat öğrenin.",
        "Skat Trainer'a hoş geldiniz. Kartları, ihaleyi, oyun türlerini ve kart atmayı çalışın.",
        "tr",
    ),
    "el": localized(
        "Skat Trainer: Μάθε Σκατ",
        "Μάθε Σκατ, χέρι με χέρι",
        "skat,κάρτες,μάθηση,ατού,grand,null,λεβέ",
        "Μάθετε Σκατ με νέες διανομές, επανάληψη λαθών και πρόκληση 90 δευτερολέπτων.",
        "Καλώς ήρθατε στο Skat Trainer. Εξασκηθείτε σε κάρτες, πλειοδοσία, παιχνίδι και λεβέ.",
        "el",
    ),
    "hr": localized(
        "Skat Trainer: Nauči Skat",
        "Skat, uči igru iz ruke",
        "skat,karte,njemačka igra,učenje,licitacija,adut,grand,null,odlaganje,štih,kviz,pravila",
        "Nauči Skat uz nove ruke, ponavljanje pogrešaka i izazov od 90 sekundi.",
        "Dobro došli u Skat Trainer. Vježbajte karte, licitaciju, vrste igre, odlaganje i štihove.",
        "hr",
    ),
    "sl": localized(
        "Skat Trainer: Nauči se Skat",
        "Skat, uči se iz igre v igro",
        "skat,karte,nemška igra,znanje,licitacija,adut,grand,null,odlaganje,štih,kviz,pravila",
        "Nauči se Skata z novimi razdelitvami, ponavljanjem napak in 90-sekundnim izzivom.",
        "Dobrodošli v Skat Trainerju. Vadite karte, licitiranje, vrste igre, odlaganje in štihe.",
        "sl",
    ),
    "ca": localized(
        "Skat Trainer: Aprèn Skat",
        "Aprèn Skat, mà a mà",
        "skat,cartes,joc alemany,aprendre,subhasta,triomf,grand,null,descart,bazes,quiz,estratègia,regles",
        "Aprèn Skat amb mans noves, repàs d'errors i un repte de 90 segons.",
        "Benvingut a Skat Trainer. Practica cartes, subhasta, tipus de joc, descart i bazes.",
        "ca",
    ),
    "id": localized(
        "Skat Trainer: Belajar Skat",
        "Belajar Skat, per kartu",
        "skat,kartu,permainan jerman,belajar,tawaran,trump,grand,null,buang,trik,kuis,strategi,aturan",
        "Pelajari Skat dengan tangan baru, ulangi kesalahan, dan ikuti tantangan 90 detik.",
        "Selamat datang di Skat Trainer. Latih kartu, tawaran, jenis permainan, buang kartu, dan trik.",
        "id",
    ),
    "ms": localized(
        "Skat Trainer: Belajar Skat",
        "Belajar Skat, kad demi kad",
        "skat,kad,permainan Jerman,belajar,bidaan,trump,grand,null,buang,trik,kuiz,strategi,peraturan",
        "Pelajari Skat dengan tangan baharu, ulang kesilapan dan cabaran 90 saat.",
        "Selamat datang ke Skat Trainer. Latih kad, bidaan, jenis permainan, buang kad dan trik.",
        "ms",
    ),
    "vi": localized(
        "Skat Trainer: Học chơi Skat",
        "Học Skat, từng ván một",
        "skat,lá bài,học,đấu giá,chủ,grand,null,lần",
        "Học Skat với bộ bài mới, ôn lỗi sai và thử thách 90 giây kèm giải thích rõ ràng.",
        "Chào mừng đến với Skat Trainer. Luyện lá bài, đấu giá, kiểu chơi, bỏ bài và các lần.",
        "vi",
    ),
    "th": localized(
        "Skat Trainer: เรียนสกัต",
        "เรียนสกัต ฝึกทีละมือ",
        "skat,ไพ่,เรียนรู้,ประมูล,ทรัมป์,ทริก",
        "เรียนสกัตด้วยมือไพ่ใหม่ ทบทวนข้อผิดพลาด และความท้าทาย 90 วินาที",
        "ยินดีต้อนรับสู่ Skat Trainer ฝึกไพ่ การประมูล ประเภทเกม การทิ้งไพ่ และการเล่นทริก",
        "th",
    ),
    "ja": localized(
        "Skat Trainer: スカートを学ぶ",
        "スカートを手ごとに練習",
        "skat,カード,学習,ビッド,切り札,grand,null,トリック,クイズ",
        "新しいハンド、間違いの復習、90秒チャレンジでシュカートを学べます。",
        "Skat Trainerへようこそ。カード、ビッド、ゲーム、ディスカード、トリックを練習できます。",
        "ja",
    ),
    "ko": localized(
        "Skat Trainer: 스카트 배우기",
        "스카트, 한 판씩 연습",
        "skat,카드,학습,입찰,트럼프,버리기,트릭,퀴즈",
        "새로운 핸드, 오답 복습, 90초 도전으로 Skat을 배워 보세요.",
        "Skat Trainer에 오신 것을 환영합니다. 카드, 입찰, 게임, 버리기와 트릭을 연습하세요.",
        "ko",
    ),
    "zh-Hans": localized(
        "Skat Trainer: 学习Skat",
        "Skat，逐手练习",
        "skat,纸牌,德国牌戏,学习,叫牌,主牌,grand,null,垫牌,墩牌,问答,策略,规则",
        "用新牌局、错题复习和90秒挑战，轻松学习Skat。",
        "欢迎使用Skat Trainer。在四个免费练习室中练习牌、叫牌、玩法、垫牌和墩牌。",
        "zh-Hans",
    ),
    "zh-Hant": localized(
        "Skat Trainer: 學習Skat",
        "Skat，逐手練習",
        "skat,紙牌,德國牌戲,學習,叫牌,主牌,grand,null,墊牌,墩牌,問答,策略,規則",
        "用新牌局、錯題複習和90秒挑戰，輕鬆學習Skat。",
        "歡迎使用Skat Trainer。在四個免費練習室中練習牌、叫牌、玩法、墊牌和墩牌。",
        "zh-Hant",
    ),
    "ar": localized(
        "Skat Trainer: تعلّم سكّات",
        "تعلّم سكات، يدًا بعد يد",
        "سكات,بطاقات,تعلم,مزايدة,حكم,grand,null,لمّات",
        "تعلّم سكات مع أيادٍ جديدة، ومراجعة الأخطاء، وتحدي مدته 90 ثانية.",
        "مرحباً بك في Skat Trainer. تدرّب على البطاقات والمزايدة وأنواع اللعب والتخلّص واللمّات.",
        "ar",
    ),
    "he": localized(
        "Skat Trainer: ללמוד סקאט",
        "סקאט, מתרגלים יד אחר יד",
        "סקאט,קלפים,לימוד,הכרזה,טראמפ,grand,null,לקיחות",
        "למדו סקאט עם ידיים חדשות, חזרה על טעויות ואתגר של 90 שניות.",
        "ברוכים הבאים ל-Skat Trainer. תרגלו קלפים, הכרזות, סוגי משחק, זריקה ולקיחות.",
        "he",
    ),
    "hi": localized(
        "Skat Trainer: स्काट सीखें",
        "स्काट, हाथ दर हाथ अभ्यास",
        "skat,कार्ड,सीखें,बोली,ट्रम्प,चाल,क्विज",
        "नए हाथों, गलतियों की समीक्षा और 90 सेकंड की चुनौती के साथ स्काट सीखें।",
        "Skat Trainer में आपका स्वागत है। कार्ड, बोली, खेल के प्रकार और चाल का अभ्यास करें।",
        "hi",
    ),
    "mr": localized(
        "Skat Trainer: स्कॅट शिका",
        "स्कॅट, हात हाताने सराव",
        "skat,पत्ते,शिका,बोली,ट्रम्प,हात,क्विझ",
        "नवीन हात, चुका पुन्हा पाहणे आणि 90 सेकंदांच्या आव्हानासह स्कॅट शिका.",
        "Skat Trainer मध्ये स्वागत. पत्ते, बोली, खेळाचे प्रकार आणि हातांचा सराव करा.",
        "mr",
    ),
    "bn": localized(
        "Skat Trainer: স্কাট শিখুন",
        "স্কাট, হাতে হাতে অনুশীলন",
        "skat,তাস,শেখা,বিড,ট্রাম্প,ট্রিক,কুইজ",
        "নতুন হাত, ভুলের পুনরাবৃত্তি এবং ৯০ সেকেন্ডের চ্যালেঞ্জ দিয়ে স্কাট শিখুন।",
        "Skat Trainer-এ স্বাগতম। তাস, বিড, খেলার ধরন, তাস ফেলা এবং ট্রিক অনুশীলন করুন।",
        "bn",
    ),
    "gu": localized(
        "Skat Trainer: સ્કાટ શીખો",
        "સ્કાટ, હાથ હાથનો અભ્યાસ",
        "skat,પત્તા,શીખો,બિડ,ટ્રમ્પ,ટ્રિક",
        "નવા હાથ, ભૂલોની સમીક્ષા અને 90 સેકન્ડના પડકાર સાથે સ્કાટ શીખો.",
        "Skat Trainerમાં આપનું સ્વાગત છે. પત્તા, બિડ, રમતના પ્રકાર અને ટ્રિકનો અભ્યાસ કરો.",
        "gu",
    ),
    "kn": localized(
        "Skat Trainer: ಸ್ಕಾಟ್ ಕಲಿಯಿರಿ",
        "ಸ್ಕಾಟ್, ಕೈ ಕೈಯಾಗಿ ಅಭ್ಯಾಸ",
        "skat,ಕಾರ್ಡ್,ಕಲಿಯಿರಿ,ಬಿಡ್,ಟ್ರಿಕ್,ಕ್ವಿಜ್",
        "ಹೊಸ ಕೈಗಳು, ತಪ್ಪುಗಳ ಮರುಅಭ್ಯಾಸ ಮತ್ತು 90 ಸೆಕೆಂಡಿನ ಸವಾಲಿನೊಂದಿಗೆ ಸ್ಕಾಟ್ ಕಲಿಯಿರಿ.",
        "Skat Trainerಗೆ ಸ್ವಾಗತ. ಕಾರ್ಡ್, ಬಿಡ್, ಆಟದ ವಿಧಗಳು ಮತ್ತು ಟ್ರಿಕ್ ಅಭ್ಯಾಸ ಮಾಡಿ.",
        "kn",
    ),
    "ml": localized(
        "Skat Trainer: സ്കാറ്റ്",
        "സ്കാറ്റ്, കൈതോറും പരിശീലനം",
        "skat,കാർഡുകൾ,പഠനം,ട്രിക്ക്,ക്വിസ്",
        "പുതിയ കൈകൾ, തെറ്റുകളുടെ ആവർത്തനം, 90 സെക്കൻഡ് ചലഞ്ച് എന്നിവയിലൂടെ സ്കാറ്റ് പഠിക്കൂ.",
        "Skat Trainerലേക്ക് സ്വാഗതം. കാർഡുകളും ബിഡ്ഡിംഗും കളിരീതികളും ട്രിക്കുകളും പരിശീലിക്കൂ.",
        "ml",
    ),
    "or": localized(
        "Skat Trainer: ସ୍କାଟ ଶିଖନ୍ତୁ",
        "ସ୍କାଟ, ହାତ ପରେ ହାତ ଅଭ୍ୟାସ",
        "skat,ତାସ,ଶିଖନ୍ତୁ,ବିଡ,ଟ୍ରିକ,କୁଇଜ",
        "ନୂଆ ହାତ, ଭୁଲ ପୁନରାବୃତ୍ତି ଏବଂ ୯୦ ସେକେଣ୍ଡ ଚ୍ୟାଲେଞ୍ଜ ସହିତ ସ୍କାଟ ଶିଖନ୍ତୁ।",
        "Skat Trainerକୁ ସ୍ୱାଗତ। ତାସ, ବିଡ, ଖେଳ ପ୍ରକାର ଏବଂ ଟ୍ରିକ ଅଭ୍ୟାସ କରନ୍ତୁ।",
        "or",
    ),
    "pa": localized(
        "Skat Trainer: ਸਕੈਟ ਸਿੱਖੋ",
        "ਸਕੈਟ, ਹੱਥ ਦਰ ਹੱਥ ਅਭਿਆਸ",
        "skat,ਤਾਸ਼,ਸਿੱਖੋ,ਬੋਲੀ,ਟਰੰਪ,ਚਾਲ,ਕੁਇਜ਼",
        "ਨਵੇਂ ਹੱਥਾਂ, ਗਲਤੀਆਂ ਦੀ ਸਮੀਖਿਆ ਅਤੇ 90 ਸਕਿੰਟ ਦੀ ਚੁਣੌਤੀ ਨਾਲ ਸਕੈਟ ਸਿੱਖੋ।",
        "Skat Trainer ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ। ਤਾਸ਼, ਬੋਲੀ, ਖੇਡ ਕਿਸਮਾਂ ਅਤੇ ਚਾਲ ਦਾ ਅਭਿਆਸ ਕਰੋ।",
        "pa",
    ),
    "ta": localized(
        "Skat Trainer: ஸ்காட்",
        "ஸ்காட், கை கைமாகப் பயிற்சி",
        "skat,சீட்டுகள்,கற்றல்,ஏலம்,ட்ரிக்",
        "புதிய கைகள், தவறுகளை மீண்டும் பயிற்சி செய்தல் மற்றும் 90 விநாடி சவாலுடன் ஸ்காட் கற்றுக்கொள்ளுங்கள்.",
        "Skat Trainerக்கு வரவேற்கிறோம். சீட்டுகள், ஏலம், விளையாட்டு வகைகள் மற்றும் ட்ரிக் பயிற்சி செய்யுங்கள்.",
        "ta",
    ),
    "te": localized(
        "Skat Trainer: స్కాట్",
        "స్కాట్, చేతి చేతికి సాధన",
        "skat,కార్డులు,నేర్చుకోండి,బిడ్,ట్రిక్",
        "కొత్త చేతులు, తప్పుల పునరావృతం మరియు 90 సెకన్ల సవాలుతో స్కాట్ నేర్చుకోండి.",
        "Skat Trainerకు స్వాగతం. కార్డులు, బిడ్, ఆట రకాలు మరియు ట్రిక్ సాధన చేయండి.",
        "te",
    ),
    "ur": localized(
        "Skat Trainer: اسکیٹ سیکھیں",
        "اسکیٹ، ہاتھ بہ ہاتھ مشق",
        "skat,تاش,سیکھیں,بولی,ٹرمپ,چال",
        "نئے ہاتھوں، غلطیوں کی مشق اور 90 سیکنڈ کے چیلنج کے ساتھ اسکیٹ سیکھیں۔",
        "Skat Trainer میں خوش آمدید۔ تاش، بولی، کھیل کی اقسام اور چال کی مشق کریں۔",
        "ur",
    ),
}


LOCALE_DATA = {
    "ar-SA": "ar",
    "bn-BD": "bn",
    "ca": "ca",
    "cs": "cs",
    "da": "da",
    "de-DE": "de",
    "el": "el",
    "en-AU": "en-GB",
    "en-CA": "en",
    "en-GB": "en-GB",
    "en-US": "en",
    "es-ES": "es",
    "es-MX": "es",
    "fi": "fi",
    "fr-CA": "fr",
    "fr-FR": "fr",
    "gu-IN": "gu",
    "he": "he",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "kn-IN": "kn",
    "ko": "ko",
    "ml-IN": "ml",
    "mr-IN": "mr",
    "ms": "ms",
    "nl-NL": "nl",
    "no": "no",
    "or-IN": "or",
    "pa-IN": "pa",
    "pl": "pl",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sl-SI": "sl",
    "sv": "sv",
    "ta-IN": "ta",
    "te-IN": "te",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "ur-PK": "ur",
    "vi": "vi",
    "zh-Hans": "zh-Hans",
    "zh-Hant": "zh-Hant",
}


FIELDS = (
    "name",
    "subtitle",
    "keywords",
    "description",
    "promotional_text",
    "release_notes",
    "support_url",
    "marketing_url",
    "privacy_url",
    "apple_tv_privacy_policy",
)


def write_meta(locale: str, field: str, value: str) -> None:
    path = METADATA / locale / f"{field}.txt"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{value.strip()}\n", encoding="utf-8")


def validate(locale: str, data: dict[str, str]) -> None:
    limits = {
        "name": 30,
        "subtitle": 30,
        "keywords": 100,
        "promotional_text": 170,
        "description": 4000,
    }
    for field, limit in limits.items():
        value = data[field]
        measured = len(value.encode("utf-8")) if field == "keywords" else len(value)
        if not value.strip():
            raise ValueError(f"{locale}/{field} is empty")
        if measured > limit:
            raise ValueError(f"{locale}/{field} is {measured}, limit is {limit}")
        if "—" in value:
            raise ValueError(f"{locale}/{field} contains an em dash")


def main() -> int:
    supported_locales = json.loads(LOCALES_FILE.read_text(encoding="utf-8"))["locales"]
    missing = sorted(set(supported_locales) - set(LOCALE_DATA))
    if missing:
        raise SystemExit(f"missing locale mapping: {', '.join(missing)}")

    for locale in supported_locales:
        language = LOCALE_DATA[locale]
        if language not in DATA:
            raise SystemExit(f"missing metadata data for {locale}: {language}")
        values = dict(DATA[language])
        values["description"] = values["description"].format(
            terms_url=TERMS_URL,
            privacy_url=PRIVACY_URL,
        )
        validate(locale, values)
        values.update(
            support_url=SUPPORT_URL,
            marketing_url=MARKETING_URL,
            privacy_url=PRIVACY_URL,
            apple_tv_privacy_policy="",
        )
        for field in FIELDS:
            write_meta(locale, field, values[field])

    print(f"Generated localized App Store metadata for {len(supported_locales)} locales")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
