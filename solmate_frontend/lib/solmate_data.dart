class SolmateAnimal {
  final String name;
  final String imageUrl;

  SolmateAnimal({required this.name, required this.imageUrl});
}

final List<SolmateAnimal> solmateAnimals = [
  SolmateAnimal(name: "Dragon", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/149.png"), // Dragonite
  SolmateAnimal(name: "Dino", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"), // Bulbasaur
  SolmateAnimal(name: "Frog", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/6.png"), // Charizard (close enough to a lizard/dino)
  SolmateAnimal(name: "Dog", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/58.png"), // Growlithe
  SolmateAnimal(name: "Cat", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/52.png"), // Meowth
  SolmateAnimal(name: "Bird", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/16.png"), // Pidgey
  SolmateAnimal(name: "Fish", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/129.png"), // Magikarp
  SolmateAnimal(name: "Bear", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/217.png"), // Ursaring
  SolmateAnimal(name: "Rabbit", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/300.png"), // Skitty
  SolmateAnimal(name: "Mouse", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"), // Pikachu
  SolmateAnimal(name: "Turtle", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"), // Squirtle
  SolmateAnimal(name: "Snake", imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/23.png"), // Ekans
];