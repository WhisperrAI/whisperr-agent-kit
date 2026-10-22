import 'models.dart';

const lessons = <Lesson>[
  Lesson(
    id: 'les_greetings',
    unit: 'Unit 1 · First words',
    title: 'Greetings',
    summary: 'Say hello, introduce yourself and ask how someone is.',
    minutes: 5,
    questions: [
      Question('How do you say "Good morning"?', ['Buenos días', 'Buenas noches', 'Hasta luego'], 0),
      Question('"Me llamo Ana" means…', ['I live in Ana', 'My name is Ana', 'I like Ana'], 1),
      Question('Pick the reply to "¿Qué tal?"', ['Muy bien, gracias', 'Tengo hambre', 'Son las tres'], 0),
    ],
  ),
  Lesson(
    id: 'les_cafe',
    unit: 'Unit 1 · First words',
    title: 'At the café',
    summary: 'Order a coffee, ask for the bill and say thank you.',
    minutes: 5,
    questions: [
      Question('"Un café con leche, por favor" orders…', ['A black coffee', 'A coffee with milk', 'A tea'], 1),
      Question('How do you ask for the bill?', ['¿Dónde está el baño?', 'La cuenta, por favor', '¿Cuánto tiempo?'], 1),
      Question('"Gracias" means…', ['Please', 'Sorry', 'Thank you'], 2),
    ],
  ),
  Lesson(
    id: 'les_directions',
    unit: 'Unit 1 · First words',
    title: 'Finding your way',
    summary: 'Ask where things are and understand left, right and straight on.',
    minutes: 5,
    questions: [
      Question('"A la izquierda" means…', ['To the left', 'To the right', 'Straight on'], 0),
      Question('How do you ask "Where is the station?"', ['¿Qué hora es?', '¿Dónde está la estación?', '¿Cómo estás?'], 1),
      Question('"Todo recto" means…', ['Turn around', 'Straight on', 'Next to'], 1),
    ],
  ),
  Lesson(
    id: 'les_hotel',
    unit: 'Unit 2 · Travel',
    title: 'Checking in',
    summary: 'Book a room, check in and ask about breakfast.',
    minutes: 5,
    premium: true,
    questions: [
      Question('"Tengo una reserva" means…', ['I have a reservation', 'I need a room', 'I am leaving'], 0),
      Question('How do you ask "Is breakfast included?"', ['¿El desayuno está incluido?', '¿Hay wifi?', '¿A qué hora?'], 0),
      Question('"La llave" is…', ['The bill', 'The key', 'The lift'], 1),
    ],
  ),
  Lesson(
    id: 'les_market',
    unit: 'Unit 2 · Travel',
    title: 'At the market',
    summary: 'Ask for prices, numbers up to 100 and haggle politely.',
    minutes: 5,
    premium: true,
    questions: [
      Question('"¿Cuánto cuesta?" asks…', ['How much is it?', 'What is it?', 'Where is it?'], 0),
      Question('"Cincuenta" is…', ['15', '50', '500'], 1),
      Question('"Es demasiado caro" means…', ["It's too expensive", "It's very cheap", "It's broken"], 0),
    ],
  ),
];

const plans = <Plan>[
  Plan(id: 'premium_monthly', title: 'Monthly', period: BillingPeriod.month, priceCents: 1299),
  Plan(id: 'premium_annual', title: 'Annual', period: BillingPeriod.year, priceCents: 7999),
];

/// Profile details the fake backend already knows for some accounts.
const demoProfiles = <String, ({String phone, String billingAddress})>{
  'jane.eval@example.com': (phone: '+15555550123', billingAddress: '221B Eval Street, London NW1 6XE'),
};

/// Signing up with one of these emails fails: the address already has an account.
const takenEmails = {'taken@example.com'};

/// Payments with one of these cards are declined.
const declinedCards = {'4000000000000002'};
