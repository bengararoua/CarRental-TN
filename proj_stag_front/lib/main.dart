// Importation du package Material Design de Flutter pour les widgets
import 'package:flutter/material.dart';

// Importation du package Provider pour la gestion d'état dans l'application
//permettre à différents widgets de partager et accéder aux mêmes données sans avoir à passer ces données manuellement de parent à enfant à chaque fois.
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
  Widget build(BuildContext context) {
    // ChangeNotifierProvider est un widget fourni par le package Provider
    // Il fournit une instance de VehiclesProvider à tout l'arbre de widgets en dessous de lui
    return ChangeNotifierProvider(
      // Crée une instance de VehiclesProvider lors de l'initialisation
      // Cette instance gérera l'état des véhicules dans l'application
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