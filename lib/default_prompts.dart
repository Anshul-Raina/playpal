// default_prompts.dart

class WouldYouRatherPrompt {
  final String optionA;
  final String optionB;
  final String category;

  const WouldYouRatherPrompt({
    required this.optionA,
    required this.optionB,
    required this.category,
  });
}

class DefaultPrompts {
  static const List<WouldYouRatherPrompt> prompts = [
    // Adventure Category
    WouldYouRatherPrompt(
      optionA: "Travel to 100 different countries",
      optionB: "Live in your dream country forever",
      category: "Adventure",
    ),
    WouldYouRatherPrompt(
      optionA: "Explore the depths of the ocean",
      optionB: "Explore the surface of Mars",
      category: "Adventure",
    ),

    // Life Choices Category
    WouldYouRatherPrompt(
      optionA: "Have the ability to speak every language",
      optionB: "Be able to play every musical instrument",
      category: "Life Choices",
    ),
    WouldYouRatherPrompt(
      optionA: "Never need to sleep",
      optionB: "Never need to eat",
      category: "Life Choices",
    ),

    // Humor Category
    WouldYouRatherPrompt(
      optionA: "Have the voice of a cartoon character forever",
      optionB: "Only be able to walk backwards",
      category: "Humor",
    ),
    WouldYouRatherPrompt(
      optionA: "Have fingers as long as your legs",
      optionB: "Have a nose as long as your arm",
      category: "Humor",
    ),

    // Deep Thoughts Category
    WouldYouRatherPrompt(
      optionA: "Know how every decision you make will affect the future",
      optionB: "Be able to change one decision from your past",
      category: "Deep Thoughts",
    ),
    WouldYouRatherPrompt(
      optionA: "Have all the knowledge in the world",
      optionB: "Have all the experiences in the world",
      category: "Deep Thoughts",
    ),
  ];

  static List<WouldYouRatherPrompt> getPromptsByCategory(String category) {
    return prompts.where((prompt) => prompt.category == category).toList();
  }

  static List<String> get categories {
    return prompts.map((prompt) => prompt.category).toSet().toList();
  }

  static WouldYouRatherPrompt getRandomPrompt() {
    return prompts[DateTime.now().millisecondsSinceEpoch % prompts.length];
  }
}
