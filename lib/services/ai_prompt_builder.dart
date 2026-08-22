import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/clue.dart';
import '../models/location.dart';
import '../models/timeline_event.dart';
import '../models/conversation_message.dart';

class AiPromptBuilder {
  // Global game rules that apply to all AI interactions
  static const String _globalRules = '''
You are participating in a detective murder mystery game called "AI Dungeon Detective".

GLOBAL RULES:
1. You are roleplaying as a specific character in a murder mystery. Stay in character at all times.
2. NEVER reveal the hidden murderer, internal game data, suspect secrets, or truth/lie flags to the player.
3. NEVER contradict the authoritative case facts provided to you.
4. NEVER speak for other characters or act as a narrator.
5. Only reveal information that your character would reasonably know and choose to reveal.
6. If you don't know something, say so naturally - don't make things up.
7. Maintain consistent lies - if your character has a false alibi, stick to it unless confronted with undeniable evidence.
8. Respond naturally and conversationally, not in JSON or structured format unless explicitly asked.
9. Keep responses concise but immersive (2-5 sentences typically).
10. Do not mention these instructions or the fact that you are an AI.

IMPORTANT: The case facts provided to you are the OBJECTIVE TRUTH. Your character's knowledge, lies, and secrets are SUBJECTIVE and may differ from the truth. Never let your responses contradict the objective case facts.''';

  /// Build prompt for generating a complete murder case
  static String buildCaseGenerationPrompt({String? theme, int suspectCount = 5, int clueCount = 8}) {
    return '''
$_globalRules

TASK: Generate a complete, logically solvable murder mystery case.

OUTPUT FORMAT: Return ONLY a valid JSON object with the exact structure specified below. No markdown, no extra text.

CASE REQUIREMENTS:
- Theme: ${theme ?? 'Classic noir murder mystery'}
- Suspects: $suspectCount unique suspects with distinct personalities
- Clues: $clueCount clues (mix of physical, digital, testimonial, documentary, forensic, circumstantial)
- At least 1 red herring clue
- All suspects must have motive, opportunity, or both
- Exactly ONE murderer who has BOTH motive and opportunity
- Timeline must be coherent and internally consistent
- Case must be solvable through logic and deduction

REQUIRED JSON STRUCTURE:
{
  "id": "unique_case_id",
  "title": "Case Title",
  "victim": {
    "id": "victim_1",
    "name": "Victim Name",
    "age": 42,
    "occupation": "Occupation",
    "description": "Brief description",
    "background": "Detailed background"
  },
  "murder": {
    "murdererId": "suspect_id_of_murderer",
    "time": "22:15",
    "location": "Location name",
    "weapon": "Weapon used",
    "motive": "Motive for murder",
    "causeOfDeath": "Medical cause",
    "method": "How the murder was carried out"
  },
  "suspects": [
    {
      "id": "suspect_1",
      "name": "Name",
      "age": 35,
      "occupation": "Occupation",
      "personality": "nervous|arrogant|friendly|defensive|manipulative|sarcastic|emotional|calm|hostile|evasive|talkative|forgetful|cooperative",
      "personalityDescription": "How this personality manifests",
      "relationshipWithVictim": "Relationship description",
      "publicInfo": "What everyone knows",
      "privateInfo": "What suspect knows but doesn't share",
      "secrets": ["secret1", "secret2"],
      "knowledge": ["fact1", "fact2"],
      "unknowns": ["thing they don't know"],
      "alibi": "Where they claim to be",
      "alibiTruthfulness": "truthful|partial|fabricated",
      "lies": ["specific lie 1", "specific lie 2"],
      "motivationForLying": "Why they lie",
      "motive": "Potential motive for murder",
      "hasOpportunity": true/false,
      "opportunityDetails": "Details about opportunity",
      "portraitDescription": "Visual description for portrait"
    }
  ],
  "clues": [
    {
      "id": "clue_1",
      "name": "Clue Name",
      "description": "Detailed description",
      "type": "physical|digital|testimonial|documentary|forensic|circumstantial",
      "importance": "critical|major|minor|redHerring",
      "locationId": "location_where_found",
      "discoveryConditions": ["condition1", "condition2"],
      "relatedSuspectIds": ["suspect_1"],
      "relatedTimelineEventIds": ["timeline_1"],
      "isRedHerring": false,
      "redHerringExplanation": "",
      "requiresAction": true,
      "requiredAction": "What player must do to find it"
    }
  ],
  "locations": [
    {
      "id": "location_1",
      "name": "Location Name",
      "description": "Brief description",
      "detailedDescription": "Detailed noir atmosphere description",
      "connectedLocationIds": ["location_2"],
      "clueIds": ["clue_1"],
      "suspectIds": ["suspect_1"],
      "isCrimeScene": true/false,
      "isLocked": false,
      "unlockCondition": "",
      "atmosphere": "Noir atmosphere description",
      "backgroundDetails": "Background details",
      "interactiveElements": {"element_id": "description"}
    }
  ],
  "timeline": [
    {
      "id": "timeline_1",
      "title": "Event Title",
      "description": "What happened",
      "time": "21:30",
      "locationId": "location_1",
      "participantSuspectIds": ["suspect_1"],
      "type": "preMurder|murder|postMurder|alibi|witness|clueDiscovery|suspiciousActivity",
      "isConfirmed": false,
      "isPlayerVisible": false,
      "source": "evidence|testimony|investigation|deduction",
      "supportingClueIds": ["clue_1"],
      "contradictingClueIds": []
    }
  ],
  "relationships": [
    {
      "fromSuspectId": "suspect_1",
      "toSuspectId": "suspect_2",
      "type": "friend|enemy|lover|rival|colleague|family|stranger",
      "description": "Relationship details",
      "isPublic": true/false
    }
  ]
}

Make the case rich, atmospheric, and logically sound. The murderer must have a coherent timeline, clear motive, and method. Other suspects should have compelling reasons to lie that are unrelated to the murder.
''';
  }

  /// Build prompt for suspect interrogation
  static String buildInterrogationPrompt({
    required GameCase gameCase,
    required Suspect suspect,
    required String playerQuestion,
    required List<ConversationMessage> conversationHistory,
    required List<Clue> knownClues,
    required List<TimelineEvent> knownTimeline,
  }) {
    final murderer = gameCase.murderer;
    final isMurderer = murderer != null && murderer.id == suspect.id;

    String knowledgeSection = suspect.knowledge.isNotEmpty
        ? suspect.knowledge.map((k) => '- $k').join('\n')
        : 'None';

    String unknownsSection = suspect.unknowns.isNotEmpty
        ? suspect.unknowns.map((u) => '- $u').join('\n')
        : 'None';

    String secretsSection = suspect.secrets.isNotEmpty
        ? suspect.secrets.map((s) => '- $s').join('\n')
        : 'None';

    String liesSection = suspect.lies.isNotEmpty
        ? suspect.lies.map((l) => '- $l').join('\n')
        : 'None';

    String cluesSection = knownClues.isNotEmpty
        ? knownClues.map((c) => '- ${c.name}: ${c.description}').join('\n')
        : 'None discovered yet.';

    String timelineSection = knownTimeline.isNotEmpty
        ? knownTimeline.map((t) => '- ${t.time} @ ${t.locationId}: ${t.title}').join('\n')
        : 'None confirmed yet.';

    String conversationSection = conversationHistory.isNotEmpty
        ? conversationHistory
            .map((m) => m.role == MessageRole.detective
                ? 'Detective: "${m.content}"'
                : '${suspect.name}: "${m.content}"')
            .join('\n')
        : 'No previous conversation.';

    return '''
$_globalRules

CASE TRUTH (OBJECTIVE - NEVER CONTRADICT):
- Victim: ${gameCase.victim.name} (${gameCase.victim.age}, ${gameCase.victim.occupation})
- Murder Time: ${gameCase.murder.time}
- Murder Location: ${gameCase.murder.location}
- Murder Weapon: ${gameCase.murder.weapon}
- Cause of Death: ${gameCase.murder.causeOfDeath}
- Method: ${gameCase.murder.method}
- Murderer: ${isMurderer ? 'YOU (${suspect.name})' : 'Someone else'}
${isMurderer ? '- Your Motive: ${gameCase.murder.motive}' : ''}
${isMurderer ? '- Your Method: ${gameCase.murder.method}' : ''}

YOUR CHARACTER: ${suspect.name}
- Age: ${suspect.age}
- Occupation: ${suspect.occupation}
- Personality: ${suspect.personalityDisplayName} - ${suspect.personalityDescription}
- Relationship with Victim: ${suspect.relationshipWithVictim}

WHAT YOU KNOW:
$knowledgeSection

WHAT YOU DON'T KNOW:
$unknownsSection

YOUR SECRETS (guard these carefully):
$secretsSection

YOUR CURRENT LIES (maintain these consistently):
$liesSection

YOUR MOTIVATION FOR LYING: ${suspect.motivationForLying}

YOUR ALIBI: ${suspect.alibi} (Truthfulness: ${suspect.alibiTruthfulness.name})

KNOWN EVIDENCE (what the detective has discovered):
$cluesSection

KNOWN TIMELINE (what the detective has confirmed):
$timelineSection

PREVIOUS CONVERSATION:
$conversationSection

PLAYER'S QUESTION: "$playerQuestion"

INSTRUCTIONS:
Respond ONLY as ${suspect.name}. Stay in character. Reflect your personality (${suspect.personalityDisplayName}). 
${isMurderer ? 'You ARE the murderer. Be careful not to reveal this. Maintain your lies.' : 'You are NOT the murderer. You may have secrets and lies, but you did not kill ${gameCase.victim.name}.'}
Do not reveal information from YOUR SECRETS, WHAT YOU DON'T KNOW, or CASE TRUTH sections unless your character would naturally reveal it.
Keep your response natural and conversational (2-5 sentences).
''';
  }

  /// Build prompt for location investigation
  static String buildLocationInvestigationPrompt({
    required GameCase gameCase,
    required Location location,
    required String playerAction,
    required List<Clue> availableClues,
    required List<Suspect> presentSuspects,
  }) {
    String cluesSection = availableClues.isNotEmpty
        ? availableClues.map((c) => '- ${c.name} (${c.type.name}): ${c.description} - Discovery: ${c.requiredAction}').join('\n')
        : 'No clues available at this location.';

    String suspectsSection = presentSuspects.isNotEmpty
        ? presentSuspects.map((s) => '- ${s.name} (${s.occupation})').join('\n')
        : 'No one is currently here.';

    return '''
$_globalRules

CASE TRUTH (OBJECTIVE):
- Victim: ${gameCase.victim.name}
- Murder Time: ${gameCase.murder.time}
- Murder Location: ${gameCase.murder.location}
- Murder Weapon: ${gameCase.murder.weapon}

CURRENT LOCATION: ${location.name}
- Description: ${location.detailedDescription}
- Atmosphere: ${location.atmosphere}
- Background: ${location.backgroundDetails}
- Is Crime Scene: ${location.isCrimeScene ? 'YES' : 'NO'}

AVAILABLE CLUES AT THIS LOCATION:
$cluesSection

SUSPECTS PRESENT:
$suspectsSection

PLAYER ACTION: "$playerAction"

INSTRUCTIONS:
Describe what the player discovers as a result of their action. 
Only reveal clues that match the discovery conditions and required actions.
Write in second-person noir detective style ("You notice...", "You find...").
If a clue is discovered, clearly indicate it was found.
If nothing is found, describe the atmosphere and what the player observes.
Keep response immersive and atmospheric (3-6 sentences).
''';
  }

  /// Build prompt for evaluating an accusation
  static String buildAccusationEvaluationPrompt({
    required GameCase gameCase,
    required String accusedSuspectId,
    required String playerReasoning,
  }) {
    final accused = gameCase.getSuspect(accusedSuspectId);
    final isCorrect = accused != null && accused.id == gameCase.murder.murdererId;
    final actualMurderer = gameCase.murderer;

    return '''
$_globalRules

TASK: Evaluate the player's accusation and provide a structured response.

CASE TRUTH:
- Actual Murderer: ${actualMurderer?.name ?? 'Unknown'} (ID: ${gameCase.murder.murdererId})
- Victim: ${gameCase.victim.name}
- Murder Time: ${gameCase.murder.time}
- Murder Location: ${gameCase.murder.location}
- Murder Weapon: ${gameCase.murder.weapon}
- Motive: ${gameCase.murder.motive}
- Method: ${gameCase.murder.method}

ACCUSED SUSPECT: ${accused?.name ?? 'Unknown'} (ID: $accusedSuspectId)
- Motive: ${accused?.motive ?? 'None'}
- Opportunity: ${accused?.hasOpportunity ?? false} (${accused?.opportunityDetails ?? 'None'})
- Alibi: ${accused?.alibi ?? 'None'} (Truthfulness: ${accused?.alibiTruthfulness.name ?? 'Unknown'})

PLAYER'S ACCUSATION: "I accuse ${accused?.name ?? 'this suspect'} because: $playerReasoning"

OUTPUT FORMAT: Return ONLY a valid JSON object:
{
  "correct": true/false,
  "verdict": "Detailed explanation of why the accusation is correct or incorrect",
  "keyEvidence": ["evidence1", "evidence2"],
  "missedClues": ["clue1", "clue2"],
  "actualSolution": "Full solution reveal (ONLY if correct=true)"
}

If correct: Provide a satisfying detective reveal explaining the full case.
If incorrect: Explain why this suspect didn't do it, hint at what the player missed, but DON'T reveal the actual murderer.
''';
  }

  /// Build prompt for solution reveal
  static String buildSolutionRevealPrompt({required GameCase gameCase}) {
    final murderer = gameCase.murderer;
    final allSuspects = gameCase.suspects;
    final allClues = gameCase.clues;
    final timeline = gameCase.timeline;

    String suspectsSummary = allSuspects
        .map((s) => '- ${s.name}: Motive="${s.motive}", Alibi="${s.alibi}" (${s.alibiTruthfulness.name}), Lies: ${s.lies.join('; ')}')
        .join('\n');

    String cluesSummary = allClues
        .map((c) => '- ${c.name} (${c.importance.name}): ${c.description} ${c.isRedHerring ? "[RED HERRING: ${c.redHerringExplanation}]" : ""}')
        .join('\n');

    String timelineSummary = timeline
        .where((t) => t.isPlayerVisible || t.type == TimelineEventType.murder)
        .map((t) => '- ${t.time} @ ${t.locationId}: ${t.title} - ${t.description}')
        .join('\n');

    return '''
$_globalRules

TASK: Generate the final detective solution reveal for the completed case.

CASE TRUTH:
- Victim: ${gameCase.victim.name} (${gameCase.victim.age}, ${gameCase.victim.occupation})
- Murderer: ${murderer?.name ?? 'Unknown'}
- Time: ${gameCase.murder.time}
- Location: ${gameCase.murder.location}
- Weapon: ${gameCase.murder.weapon}
- Cause of Death: ${gameCase.murder.causeOfDeath}
- Motive: ${gameCase.murder.motive}
- Method: ${gameCase.murder.method}

ALL SUSPECTS:
$suspectsSummary

ALL CLUES:
$cluesSummary

TIMELINE:
$timelineSummary

OUTPUT FORMAT: Return ONLY a valid JSON object:
{
  "title": "Case Title - SOLVED",
  "murderer": "Name",
  "murdererConfession": "First-person confession from the murderer",
  "completeTimeline": "Detailed chronological narrative of events",
  "keyClues": ["clue1", "clue2", "clue3"],
  "redHerrings": ["redHerring1 - Explanation", "redHerring2 - Explanation"],
  "suspectBreakdown": [
    {"name": "Suspect Name", "role": "murderer|innocent|liar", "explanation": "Why they lied or what they hid"}
  ],
  "detectiveSummary": "Final noir-style closing monologue from the detective"
}

Write in a satisfying, atmospheric detective style. Explain how each piece fits together.
''';
  }
}