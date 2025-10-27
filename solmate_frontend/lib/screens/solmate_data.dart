class SolmateAnimal {
  final String name;
  final String normalSpritePath;
  final String happySpritePath;

  SolmateAnimal({required this.name, required this.normalSpritePath, required this.happySpritePath});
}

final List<SolmateAnimal> solmateAnimals = [
  SolmateAnimal(name: "Dragon", normalSpritePath: "assets/sprites/dragon_normal.png", happySpritePath: "assets/sprites/dragon_happy.png"),
  SolmateAnimal(name: "Toly", normalSpritePath: "assets/sprites/toly_normal.png", happySpritePath: "assets/sprites/dragon_happy.png"),
  SolmateAnimal(name: "Nessie", normalSpritePath: "assets/sprites/nessie_normal.png", happySpritePath: "assets/sprites/dragon_normal.png"),
  // SolmateAnimal(name: "Dog", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/58.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/58.png"), // Growlithe
  // SolmateAnimal(name: "Cat", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/52.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/52.png"), // Meowth
  // SolmateAnimal(name: "Bird", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/16.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/16.png"), // Pidgey
  // SolmateAnimal(name: "Fish", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/129.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/129.png"), // Magikarp
  // SolmateAnimal(name: "Bear", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/217.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/217.png"), // Ursaring
  // SolmateAnimal(name: "Rabbit", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/300.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/300.png"), // Skitty
  // SolmateAnimal(name: "Mouse", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"), // Pikachu
  // SolmateAnimal(name: "Turtle", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"), // Squirtle
  // SolmateAnimal(name: "Snake", normalSpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/23.png", happySpritePath: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/23.png"), // Ekans
];