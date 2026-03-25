// Importation du package Material Design de Flutter pour les widgets
import 'package:flutter/material.dart';

//Le provider est un package Flutter qui sert à partager des données entre tous les écrans sans avoir à les passer manuellement d'un écran à l'autre.
import 'package:provider/provider.dart';

// Importation de l'écran de connexion depuis le dossier screens
import 'screens/login_screen.dart';

// Importation du fournisseur (provider) de véhicules depuis le dossier providers
import 'providers/vehicles_provider.dart';

// Fonction principale qui sert de point d'entrée à l'application Flutter
// Elle exécute l'application en appelant la méthode runApp() avec une instance de MyApp
void main() => runApp(MyApp());

// Classe principale de l'application, qui étend StatelessWidget (widget sans état mutable)
// StatelessWidget est utilisé car MyApp n'a pas besoin de gérer un état interne changeant
class MyApp extends StatelessWidget {
  // Méthode build obligatoire pour tous les widgets, construit l'interface utilisateur
  @override
  //BuildContext context: représente la position du widget dans l'arbre de widgets de l'application.

  Widget build(BuildContext context) {
    // ChangeNotifierProvider est un widget fourni par le package Provider qui partager des données (state) à tous les widgets en dessous
    return ChangeNotifierProvider(
      // Crée une instance de VehiclesProvider lors de l'initialisation
      // Cette instance gérera l'état des véhicules dans l'application
      //context = info sur l’emplacement du widget
      create: (context) => VehiclesProvider(),
      // MaterialApp est le widget racine qui configure l'apparence générale et la navigation
      child: MaterialApp(
        // Titre de l'application, utilisé par le système d'exploitation dans les fenêtres de l'application
        title: 'CarRental',
        // Désactive la bannière "debug" en mode développement (coin supérieur droit)
        debugShowCheckedModeBanner: false,
        // Définit le thème de l'application avec une couleur principale bleue
        theme: ThemeData(primarySwatch: Colors.blue),
        // Définit l'écran initial au lancement de l'application (ici, l'écran de connexion)
        home: LoginScreen(),
      ),
    );
  }
}