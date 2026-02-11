# ========================================
# IMPORTATION DES MODULES NÉCESSAIRES
# ========================================

# Importation de FastAPI et de ses composants principaux pour créer l'API
#API:ensemble de règles et de méthodes permettant à des logiciels de communiquer et d’échanger des données entre eux
from fastapi import FastAPI, HTTPException, Depends, status, Form, Request
# Middleware CORS pour autoriser les requêtes cross-origin (depuis d'autres domaines)
from fastapi.middleware.cors import CORSMiddleware
# Pydantic pour la validation des données (schémas)
from pydantic import BaseModel, EmailStr
# SQLAlchemy ORM pour interagir avec la base de données
from sqlalchemy.orm import Session
# Module pour le hachage sécurisé des mots de passe
import bcrypt
# Importation de nos modèles de base de données et des dépendances
from models import User, vehicles, Favorite, Booking, Conversation, Message, Base, engine, SessionLocal
# Types Python pour les annotations de type
from typing import Optional, List
# Modules de gestion des dates et heures
from datetime import datetime, timedelta, date
# JWT pour la création et vérification des tokens d'authentification
from jose import JWTError, jwt
# OAuth2:protocole permet application d’accéder aux données d’un utilisateur sur un autre service sans connaître son mot de passe.
#OAuth2PasswordBearer:schéma d’authentification où l’utilisateur fournit un token
#OAuth2PasswordRequestForm: récupérer les infos de connexion envoyées par l’utilisateur pour obtenir un token via OAuth2.
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
# Réponse JSON personnalisée
from fastapi.responses import JSONResponse

# ========================================
# CONFIGURATION JWT (JSON WEB TOKENS)
# ========================================

# Clé secrète utilisée pour signer les tokens JWT 
SECRET_KEY = "a1d03237d6435d1d39ab8047118d622c314024ca04b478877a13e8ae238674d1"
# Algorithme de cryptage utilisé pour les tokens
ALGORITHM = "HS256"
# Durée de validité des tokens d'accès en minutes
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ========================================
# INITIALISATION DE LA BASE DE DONNÉES
# ========================================

# Création de toutes les tables définies dans les modèles SQLAlchemy
# Si les tables existent déjà, cette commande ne fait rien
Base.metadata.create_all(bind=engine)

# ========================================
# INITIALISATION DE L'APPLICATION FASTAPI
# ========================================

# Création de l'instance principale de l'application FastAPI
app = FastAPI(title="API d'Authentification", version="1.0.0")

# ========================================
# CONFIGURATION CORS (Cross-Origin Resource Sharing)
# ========================================

# Ajout du middleware CORS pour autoriser les requêtes depuis n'importe quelle origine
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Autorise toutes les origines 
    allow_credentials=True,  # Autorise l'envoi de cookies
    allow_methods=["*"],  # Autorise toutes les méthodes HTTP (GET, POST, etc.)
    allow_headers=["*"],  # Autorise tous les en-têtes HTTP
)

# ========================================
# FONCTIONS UTILITAIRES DE BASE DE DONNÉES
# ========================================

def get_db():
    # Création d'une nouvelle session de base de données
    db = SessionLocal()
    try:
        # Yield retourne la session à la fonction appelante
        yield db
    finally:
        # Ferme la session après utilisation (même en cas d'erreur)
        db.close()

# ========================================
# FONCTIONS UTILITAIRES DE SÉCURITÉ
# ========================================

def hash_password(password: str) -> str:
    # Génère un salt aléatoire et hache le mot de passe
    #UTF-8 est un format d’encodage de caractères
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    # Compare le mot de passe fourni avec le hash stocké
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

def user_response(user: User):
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "role": user.role
    }

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    # Copie des données pour éviter la modification de l'original
    to_encode = data.copy()
    
    # Détermination de la date d'expiration
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Ajout de la date d'expiration aux données encodées
    to_encode.update({"exp": expire})
    # Encodage des données en token JWT
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ========================================
# MODÈLES PYDANTIC POUR LA VALIDATION
# ========================================

class UserRegister(BaseModel):
    username: str  # Nom d'utilisateur requis
    email: EmailStr  # Email valide requis (validation automatique)
    password: str  # Mot de passe requis
class UserLogin(BaseModel):
    email: EmailStr  # Email valide requis
    password: str  # Mot de passe requis
class ResetPassword(BaseModel):
    email: EmailStr  # Email de l'utilisateur
    new_password: str  # Nouveau mot de passe
class FavoriteRequest(BaseModel):
    car_id: int  # ID du véhicule à ajouter

class BookingCreate(BaseModel):

    car_id: int  # ID du véhicule réservé
    full_name: str  # Nom complet du client
    pickup_date: str  # Date de prise en charge (format string)
    return_date: str  # Date de retour (format string)
    total_price: float  # Prix total de la location

class BookingResponse(BaseModel):

    id: int  # ID de la réservation
    car_id: int  # ID du véhicule
    user_id: int  # ID de l'utilisateur
    full_name: str  # Nom complet
    pickup_date: date  # Date de prise en charge
    return_date: date  # Date de retour
    total_price: float  # Prix total
    status: str  # Statut de la réservation
    created_at: Optional[datetime]  # Date de création (optionnelle)
#from_attributes = True:Pydantic peut aussi lire les objets (comme SQLAlchemy) et leurs attributs pour créer le modèle.
    class Config:
        # Permet la conversion depuis les objets SQLAlchemy
        from_attributes = True

class UpdateProfileRequest(BaseModel):

    username: Optional[str] = None  # Nouveau nom d'utilisateur (optionnel)
    email: Optional[str] = None  # Nouvel email (optionnel)
    current_password: Optional[str] = None  # Mot de passe actuel (pour vérification)
    new_password: Optional[str] = None  # Nouveau mot de passe (optionnel)

class ConversationCreate(BaseModel):

    title: Optional[str] = "Nouvelle conversation"  # Titre par défaut

class MessageCreate(BaseModel):
  
    content: str  # Contenu du message
    is_user: bool = True  # Indique si le message vient de l'utilisateur ou du bot

class MessageResponse(BaseModel):
  
    id: int  # ID du message
    conversation_id: int  # ID de la conversation
    content: str  # Contenu du message
    is_user: bool  # Émetteur du message
    created_at: datetime  # Date de création

    class Config:
        #Pydantic peut aussi lire les objets (comme SQLAlchemy) et leurs attributs pour créer le modèle.
        from_attributes = True  # Compatibilité avec SQLAlchemy

class ConversationResponse(BaseModel):
  
    id: int  # ID de la conversation
    user_id: int  # ID de l'utilisateur
    title: str  # Titre de la conversation
    created_at: datetime  # Date de création
    updated_at: datetime  # Date de dernière mise à jour
    is_active: bool  # Statut actif/inactif
    messages: List[MessageResponse] = []  # Liste des messages associés

    class Config:
        from_attributes = True

class ConversationListResponse(BaseModel):

    id: int  # ID de la conversation
    title: str  # Titre
    created_at: datetime  # Date de création
    updated_at: datetime  # Date de mise à jour
    message_count: int  # Nombre total de messages
    last_message: Optional[str] = None  # Dernier message (optionnel)

    class Config:
        from_attributes = True

# Modèle pour l'assistant de chat
class ChatInput(BaseModel):

    conversation_id: int  # ID de la conversation en cours
    content: str  # Message de l'utilisateur

# ========================================
# CONFIGURATION OAUTH2
# ========================================

# Définit le schéma OAuth2 pour l'authentification par token
# Le paramètre tokenUrl pointe vers l'endpoint de connexion
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# ========================================
# ENDPOINTS D'AUTHENTIFICATION
# ========================================

@app.post("/register", status_code=status.HTTP_201_CREATED)
def register(user: UserRegister, db: Session = Depends(get_db)):

    # Vérifie si un utilisateur avec cet email existe déjà
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        # Retourne une erreur 400 si l'email est déjà utilisé
        raise HTTPException(status_code=400, detail="Email déjà utilisé")
    
    # Crée un nouvel utilisateur avec le mot de passe haché
    new_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hash_password(user.password)
    )
    
    # Ajoute l'utilisateur à la session et sauvegarde en base
    db.add(new_user)
    db.commit()  # Valide la transaction
    db.refresh(new_user)  # Rafraîchit l'objet avec les données de la base
    
    # Retourne une réponse de succès avec les informations utilisateur
    return {
        "message": "Inscription réussie",
        "user": user_response(new_user)
    }

@app.post("/login")
#Depends():permettant d’obtenir automatiquement un objet ou une valeur fournie par une autre fonction.
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):

    # Recherche l'utilisateur par email OU nom d'utilisateur
    db_user = db.query(User).filter(
        (User.email == form_data.username) | (User.username == form_data.username)
    ).first()

    # Vérifie si l'utilisateur existe ET si le mot de passe correspond
    if not db_user or not verify_password(form_data.password, db_user.hashed_password):
        # Erreur 401 en cas d'identifiants invalides
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    # Crée un token JWT avec l'email et le rôle de l'utilisateur
    access_token = create_access_token(data={"sub": db_user.email, "role": db_user.role})

    # Retourne le token et les informations utilisateur
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user_response(db_user)
    }

# ========================================
# FONCTION POUR OBTENIR L'UTILISATEUR COURANT
# ========================================

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    # Définition de l'exception en cas d'échec d'authentification
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide",
        headers={"WWW-Authenticate": "Bearer"},  # En-tête standard pour l'authentification
    )
    
    try:
        # Décodage du token JWT avec la clé secrète
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Extraction de l'email depuis le payload
        email: str = payload.get("sub")
        if email is None:
            # Si le champ 'sub' (subject) est manquant, token invalide
            raise credentials_exception
    except JWTError:
        # En cas d'erreur de décodage (token expiré, signature invalide, etc.)
        raise credentials_exception

    # Recherche de l'utilisateur dans la base de données par email
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        # Si aucun utilisateur trouvé, token invalide
        raise credentials_exception

    # Retourne l'utilisateur authentifié
    return user

@app.get("/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    # Retourne les informations formatées de l'utilisateur
    return user_response(current_user)

@app.post("/forgot-password/reset")
def reset_password(data: ResetPassword, db: Session = Depends(get_db)):
    # Recherche l'utilisateur par email
    user = db.query(User).filter(User.email == data.email).first()
    # Vérifie si l'utilisateur existe
    if not user:
        raise HTTPException(status_code=404, detail="Aucun compte associé à cet email")
    # Met à jour le mot de passe avec le nouveau hash
    user.hashed_password = hash_password(data.new_password)
    db.commit()  # Sauvegarde les modifications
    # Retourne un message de succès
    return {"message": "Mot de passe réinitialisé avec succès"}

# ========================================
# ENDPOINTS POUR LES VÉHICULES
# ========================================

@app.get("/vehicles")
def get_vehicles(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Récupère tous les véhicules de la base de données
    vehicles_list = db.query(vehicles).all()
    # Récupère les IDs des véhicules favoris de l'utilisateur connecté
    user_favorites = db.query(Favorite.car_id).filter(Favorite.user_id == current_user.id).all()
    # Transforme en liste simple d'IDs
    #Pour chaque élément fav dans user_favorites, prends sa valeur car_id et mets-la dans une nouvelle liste
    favorite_ids = [fav.car_id for fav in user_favorites]
    
    # Construit la réponse avec tous les détails des véhicules
    return [
        {
            "id": v.id,
            "name": v.name,
            "category": v.category,
            "price": float(v.price) if v.price else 0.0,  # Conversion en float avec valeur par défaut
            "image": v.image,
            "transmission": v.transmission,
            "seats": v.seats,
            "engine": v.engine,
            "year": v.year,
            "fuel": v.fuel,
            "isAvailable": v.isAvailable,
            "isFavorite": v.id in favorite_ids,  # Vérifie si le véhicule est dans les favoris
            "isNew": v.isNew,
            "isBestChoice": v.isBestChoice,
            "rating": float(v.rating) if v.rating else 0.0,
            "popularity": v.popularity,
            "luggage": v.luggage,
            "airConditioning": v.airConditioning,
            "bluetooth": v.bluetooth
        }
        for v in vehicles_list
    ]

# ========================================
# ENDPOINTS POUR LES FAVORIS
# ========================================

@app.get("/favorites")
def get_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Récupère toutes les entrées Favorites de l'utilisateur
    favorites = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    
    # Initialise la liste des véhicules favoris
    favorite_cars = []
    
    # Pour chaque favori, récupère les détails du véhicule correspondant
    for fav in favorites:
        car = db.query(vehicles).filter(vehicles.id == fav.car_id).first()
        if car:  # Vérifie que le véhicule existe toujours
            favorite_cars.append({
                "id": car.id,
                "name": car.name,
                "category": car.category,
                "price": float(car.price) if car.price else 0.0,
                "image": car.image,
                "transmission": car.transmission,
                "seats": car.seats,
                "engine": car.engine,
                "year": car.year,
                "fuel": car.fuel,
                "isAvailable": car.isAvailable,
                "isFavorite": True,  # Toujours True car ce sont les favoris
                "isNew": car.isNew,
                "isBestChoice": car.isBestChoice,
                "rating": float(car.rating) if car.rating else 0.0,
                "popularity": car.popularity,
                "luggage": car.luggage,
                "airConditioning": car.airConditioning,
                "bluetooth": car.bluetooth
            })
    
    # Retourne la liste des véhicules favoris
    return favorite_cars

@app.post("/favorites/add")
def add_favorite(favorite: FavoriteRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Vérifie que le véhicule existe
    car = db.query(vehicles).filter(vehicles.id == favorite.car_id).first()
    if not car:
        raise HTTPException(status_code=404, detail="Véhicule non trouvé")
    
    # Vérifie si le véhicule n'est pas déjà dans les favoris
    existing_favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.car_id == favorite.car_id
    ).first()
    
    if existing_favorite:
        raise HTTPException(status_code=400, detail="Déjà dans les favoris")
    
    # Crée une nouvelle entrée Favorite
    new_favorite = Favorite(
        user_id=current_user.id,
        car_id=favorite.car_id
    )
    
    # Ajoute et sauvegarde en base
    db.add(new_favorite)
    db.commit()
    
    # Retourne un message de succès
    return {"message": "Ajouté aux favoris avec succès"}

@app.delete("/favorites/remove/{car_id}")
def remove_favorite(car_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Recherche l'entrée Favorite correspondante
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.car_id == car_id
    ).first()
    
    # Vérifie si le favori existe
    if not favorite:
        raise HTTPException(status_code=404, detail="Favori non trouvé")
    
    # Supprime l'entrée de la base de données
    db.delete(favorite)
    db.commit()
    
    # Retourne un message de succès
    return {"message": "Retiré des favoris avec succès"}

@app.get("/favorites/check/{car_id}")
def check_favorite(car_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Recherche l'entrée Favorite correspondante
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.car_id == car_id
    ).first()
    # Retourne un booléen indiquant si le véhicule est favori
    return {"isFavorite": favorite is not None}
# ========================================
# ENDPOINTS POUR LES RÉSERVATIONS
# ========================================

@app.post("/bookings", response_model=dict)
def create_booking(
    booking_data: BookingCreate, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    try:
        # Conversion des dates string en objets date
        try:
            #strptime:convertit une chaîne de caractères en objet datetime
            pickup_date = datetime.strptime(booking_data.pickup_date, "%Y-%m-%d").date()
            return_date = datetime.strptime(booking_data.return_date, "%Y-%m-%d").date()
        except ValueError:
            # Erreur si le format de date est invalide
            raise HTTPException(status_code=400, detail="Format de date invalide. Utilisez YYYY-MM-DD")
        
        # Vérifie que le véhicule existe
        car = db.query(vehicles).filter(vehicles.id == booking_data.car_id).first()
        if not car:
            raise HTTPException(status_code=404, detail="Voiture non trouvée")
        
        # Vérifie la disponibilité du véhicule
        if not car.isAvailable:
            raise HTTPException(status_code=400, detail="Cette voiture n'est pas disponible")
        
        # Vérifie que la date de retour est après la date de prise en charge
        if return_date <= pickup_date:
            raise HTTPException(
                status_code=400, 
                detail=f"La date de retour ({return_date}) doit être après la date de prise en charge ({pickup_date})"
            )
        
        # Crée la nouvelle réservation
        new_booking = Booking(
            user_id=current_user.id,
            car_id=booking_data.car_id,
            full_name=booking_data.full_name,
            pickup_date=pickup_date,
            return_date=return_date,
            total_price=booking_data.total_price,
            status="En attente"  # Statut initial
        )
        
        # Ajoute et sauvegarde la réservation
        db.add(new_booking)
        db.commit()
        db.refresh(new_booking)
        
        # Importation nécessaire pour la comparaison de dates
        from datetime import date as date_class

        #rendre le véhicule indisponible si la réservation commence aujourd'hui ou avant
        if pickup_date <= date_class.today():
            car.isAvailable = False
            db.commit()
        # Retourne une réponse de succès
        return {
            "success": True,
            "message": "Réservation créée avec succès",
            "booking_id": new_booking.id,
            "status": new_booking.status
        }
    
    # Gère les exceptions HTTP spécifiques (erreurs métier)
    except HTTPException as he:
        raise he
    # Gère toutes les autres exceptions (erreurs serveur)
    except Exception as e:
        db.rollback()  # Annule la transaction en cas d'erreur
        print(f"Erreur lors de la création de la réservation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/my-bookings")
def get_user_bookings(
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    try:
        # Récupère toutes les réservations de l'utilisateur, triées par date
        bookings = db.query(Booking).filter(
            Booking.user_id == current_user.id
        ).order_by(Booking.created_at.desc()).all()
        
        # Construit la réponse avec les détails de chaque réservation
        result = []
        for booking in bookings:
            # Récupère les informations du véhicule associé
            car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
            
            result.append({
                "id": booking.id,
                "car_id": booking.car_id,
                "car_name": car.name if car else "Voiture inconnue",
                "car_image": car.image if car else "",
                "full_name": booking.full_name,
                "pickup_date": booking.pickup_date.strftime("%Y-%m-%d") if booking.pickup_date else None,
                "return_date": booking.return_date.strftime("%Y-%m-%d") if booking.return_date else None,
                "total_price": float(booking.total_price),
                "status": booking.status,
                "created_at": booking.created_at.strftime("%Y-%m-%d %H:%M:%S") if booking.created_at else None
            })
        
        return result
    
    except Exception as e:
        print(f"Erreur lors de la récupération des réservations: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

# ========================================
# ENDPOINT DE SANTÉ (HEALTH CHECK)
# ========================================

@app.get("/health")
def health_check():
    #Endpoint simple pour vérifier que l'API est en ligne et fonctionne.
  
    return {"status": "OK", "message": "API is running"}

# ========================================
# FONCTIONS ADMINISTRATEUR
# ========================================

def get_current_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        # Retourne une erreur 403 (interdit) si l'utilisateur n'est pas admin
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé. Droits administrateur requis."
        )
    return current_user

@app.get("/admin/bookings")
def get_all_bookings(
    current_admin: User = Depends(get_current_admin),  # Vérification des droits admin
    db: Session = Depends(get_db)
):
    try:
        # Récupère toutes les réservations, triées par date
        bookings = db.query(Booking).order_by(Booking.created_at.desc()).all()
        
        # Construit la réponse détaillée avec infos utilisateur et véhicule
        result = []
        for booking in bookings:
            # Récupère les infos du véhicule
            car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
            # Récupère les infos de l'utilisateur
            user = db.query(User).filter(User.id == booking.user_id).first()
            #append():méthode des listes Python qui sert à ajouter un élément à la fin d’une liste existante.
            result.append({
                "id": booking.id,
                "car_id": booking.car_id,
                "car_name": car.name if car else "Voiture inconnue",
                "car_image": car.image if car else "",
                "user_id": booking.user_id,
                "user_name": user.username if user else "Utilisateur inconnu",
                "user_email": user.email if user else "",
                "full_name": booking.full_name,
                "pickup_date": booking.pickup_date.strftime("%Y-%m-%d") if booking.pickup_date else None,
                "return_date": booking.return_date.strftime("%Y-%m-%d") if booking.return_date else None,
                "total_price": float(booking.total_price),
                "status": booking.status,
                "created_at": booking.created_at.strftime("%Y-%m-%d %H:%M:%S") if booking.created_at else None
            })
        
        return result
    
    except Exception as e:
        print(f"Erreur lors de la récupération des réservations: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")
#PATCH: méthode qui permet de modifier partiellement une ressource existante sur le serveur
@app.patch("/admin/bookings/{booking_id}/status")
def update_booking_status(
    booking_id: int,
    status: str,  # Le nouveau statut à appliquer
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    try:
        from datetime import date as date_class
        
        # Liste des statuts valides
        valid_statuses = ["En attente", "Confirmée", "Annulée", "Terminée"]
        if status not in valid_statuses:
            raise HTTPException(
                status_code=400,
                detail=f"Statut invalide. Valeurs acceptées: {', '.join(valid_statuses)}"
            )
        
        # Récupère la réservation par son ID
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if not booking:
            raise HTTPException(status_code=404, detail="Réservation non trouvée")
        
        # Sauvegarde l'ancien statut pour le message de réponse
        old_status = booking.status
        
        # Met à jour le statut
        booking.status = status
        
        # Récupère le véhicule associé
        car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
        if car:
            # Si la réservation est annulée ou terminée
            if status in ["Annulée", "Terminée"]:
                # Vérifie s'il existe d'autres réservations actives pour cette voiture
                other_active_bookings = db.query(Booking).filter(
                    Booking.car_id == booking.car_id,
                    Booking.id != booking_id,  # Exclut la réservation actuelle
                    Booking.status.in_(["Confirmée", "En attente"]),  # Réservations actives
                    Booking.pickup_date <= date_class.today(),  # Commencées ou en cours
                    Booking.return_date >= date_class.today()  # Non terminées
                ).first()
                
                # Rend disponible seulement s'il n'y a pas d'autres réservations actives
                if not other_active_bookings:
                    car.isAvailable = True
            
            # Si la réservation est confirmée
            elif status == "Confirmée":
                # Rend indisponible seulement si elle commence aujourd'hui ou avant
                if booking.pickup_date <= date_class.today():
                    car.isAvailable = False
        
        db.commit()
        
        return {
            "success": True,
            "message": f"Statut mis à jour de '{old_status}' à '{status}'",
            "booking_id": booking_id,
            "new_status": status
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"Erreur lors de la mise à jour du statut: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.delete("/admin/bookings/{booking_id}")
def delete_booking(
    booking_id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    try:
        # Récupère la réservation
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if not booking:
            raise HTTPException(status_code=404, detail="Réservation non trouvé")
        
        # Rend le véhicule disponible
        car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
        if car:
            car.isAvailable = True
        
        # Supprime la réservation
        db.delete(booking)
        db.commit()
        
        return {
            "success": True,
            "message": "Réservation supprimée avec succès"
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"Erreur lors de la suppression: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

# ========================================
# ENDPOINT DE MISE À JOUR DU PROFIL
# ========================================
#PUT:méthode qui sert à mettre à jour complètement une ressource existante sur le serveur ou à la créer si elle n’existe pas.
@app.put("/update-profile/")
async def update_profile(
    profile_data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Logs de débogage (à retirer en production)
        print(f"📥 Données reçues: {profile_data}")
        print(f"👤 Utilisateur actuel: {current_user.username} ({current_user.email})")
        
        # Vérifie le mot de passe actuel si fourni (nécessaire pour changer le mot de passe)
        if profile_data.current_password:
            if not verify_password(profile_data.current_password, current_user.hashed_password):
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Mot de passe actuel incorrect"}
                )
            print("✅ Mot de passe actuel vérifié")
        
        # Variable pour suivre si des modifications ont été faites
        updates_made = False
        
        # Mise à jour du nom d'utilisateur
        if profile_data.username and profile_data.username != current_user.username:
            # Vérifie si le nouveau nom d'utilisateur n'est pas déjà utilisé par un autre utilisateur
            existing_user = db.query(User).filter(
                User.username == profile_data.username, 
                User.id != current_user.id  # Exclut l'utilisateur courant
            ).first()
            if existing_user:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Ce nom d'utilisateur est déjà utilisé"}
                )
            current_user.username = profile_data.username
            updates_made = True
            print(f"✅ Username mis à jour: {profile_data.username}")
        
        # Mise à jour de l'email
        if profile_data.email and profile_data.email != current_user.email:
            # Vérifie si le nouvel email n'est pas déjà utilisé
            existing_user = db.query(User).filter(
                User.email == profile_data.email, 
                User.id != current_user.id
            ).first()
            if existing_user:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Cet email est déjà utilisé"}
                )
            current_user.email = profile_data.email
            updates_made = True
            print(f"✅ Email mis à jour: {profile_data.email}")
        
        # Mise à jour du mot de passe
        if profile_data.new_password:
            # Pour changer le mot de passe, l'utilisateur doit fournir le mot de passe actuel
            if not profile_data.current_password:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Le mot de passe actuel est requis pour changer le mot de passe"}
                )
            current_user.hashed_password = hash_password(profile_data.new_password)
            updates_made = True
            print("✅ Mot de passe mis à jour")
        
        # Vérifie si au moins une modification a été effectuée
        if not updates_made:
            return JSONResponse(
                status_code=400,
                content={"success": False, "message": "Aucune modification détectée"}
            )
        
        # Valide et sauvegarde les changements
        db.commit()
        db.refresh(current_user)  # Rafraîchit l'objet avec les nouvelles valeurs
        
        print("✅ Profil mis à jour avec succès")
        
        # Retourne une réponse de succès avec les nouvelles informations utilisateur
        return JSONResponse(
            status_code=200,
            content={
                "success": True,
                "message": "Profil mis à jour avec succès",
                "user": user_response(current_user)
            }
        )
        
    except Exception as e:
        # En cas d'erreur, annule la transaction
        db.rollback()
        print(f"❌ Erreur serveur: {e}")
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": f"Erreur serveur: {str(e)}"}
        )


# ========================================
# ENDPOINTS ADMIN POUR LA GESTION DES VÉHICULES
# ========================================

@app.post("/admin/vehicles")
def add_vehicle(
    vehicle_data: dict,  # Accepte un dictionnaire flexible
    current_admin: User = Depends(get_current_admin),  # Vérification admin
    db: Session = Depends(get_db)
):
    try:
        # Crée un nouvel objet véhicule avec les données fournies
        new_vehicle = vehicles(
            name=vehicle_data['name'],
            category=vehicle_data['category'],
            price=vehicle_data['price'],
            image=vehicle_data['image'],
            transmission=vehicle_data['transmission'],
            seats=vehicle_data['seats'],
            engine=vehicle_data['engine'],
            year=vehicle_data['year'],
            fuel=vehicle_data['fuel'],
            isAvailable=vehicle_data.get('isAvailable', True),  # Valeur par défaut
            isNew=vehicle_data.get('isNew', False),
            isBestChoice=vehicle_data.get('isBestChoice', False),
            rating=vehicle_data.get('rating', 0.0),
            popularity=vehicle_data.get('popularity', 0),
            luggage=vehicle_data.get('luggage', 0),
            airConditioning=vehicle_data.get('airConditioning', True),
            bluetooth=vehicle_data.get('bluetooth', True),
        )
        
        # Ajoute et sauvegarde le véhicule
        db.add(new_vehicle)
        db.commit()
        db.refresh(new_vehicle)
        
        return {
            "success": True,
            "message": "Véhicule ajouté avec succès",
            "vehicle_id": new_vehicle.id  # Retourne l'ID généré
        }
    
    except Exception as e:
        db.rollback()
        print(f"Erreur lors de l'ajout: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.delete("/admin/vehicles/{vehicle_id}")
def delete_vehicle(
    vehicle_id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    try:
        # Récupère le véhicule par son ID
        vehicle = db.query(vehicles).filter(vehicles.id == vehicle_id).first()
        
        if not vehicle:
            raise HTTPException(status_code=404, detail="Véhicule non trouvé")
        
        # Vérifie s'il y a des réservations actives pour ce véhicule
        active_bookings = db.query(Booking).filter(
            Booking.car_id == vehicle_id,
            Booking.status.in_(["En attente", "Confirmée"])  # Réservations non terminées
        ).count()
        
        # Empêche la suppression si des réservations actives existent
        if active_bookings > 0:
            raise HTTPException(
                status_code=400, 
                detail=f"Impossible de supprimer : {active_bookings} réservation(s) active(s)"
            )
        
        # Supprime les favoris associés (si non géré automatiquement par CASCADE)
        db.query(Favorite).filter(Favorite.car_id == vehicle_id).delete()
        
        # Supprime le véhicule
        db.delete(vehicle)
        db.commit()
        
        return {
            "success": True,
            "message": "Véhicule supprimé avec succès",
            "vehicle_id": vehicle_id
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"Erreur lors de la suppression: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.put("/admin/vehicles/{vehicle_id}")
def update_vehicle(
    vehicle_id: int,
    vehicle_data: dict,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    try:
        # Récupère le véhicule existant
        vehicle = db.query(vehicles).filter(vehicles.id == vehicle_id).first()
        
        if not vehicle:
            raise HTTPException(status_code=404, detail="Véhicule non trouvé")
        
        # Met à jour chaque champ fourni dans vehicle_data
        # Utilise des conditions pour ne modifier que les champs présents
        if 'name' in vehicle_data:
            vehicle.name = vehicle_data['name']
        if 'category' in vehicle_data:
            vehicle.category = vehicle_data['category']
        if 'price' in vehicle_data:
            vehicle.price = vehicle_data['price']
        if 'image' in vehicle_data:
            vehicle.image = vehicle_data['image']
        if 'transmission' in vehicle_data:
            vehicle.transmission = vehicle_data['transmission']
        if 'seats' in vehicle_data:
            vehicle.seats = vehicle_data['seats']
        if 'engine' in vehicle_data:
            vehicle.engine = vehicle_data['engine']
        if 'year' in vehicle_data:
            vehicle.year = vehicle_data['year']
        if 'fuel' in vehicle_data:
            vehicle.fuel = vehicle_data['fuel']
        if 'isAvailable' in vehicle_data:
            vehicle.isAvailable = vehicle_data['isAvailable']
        if 'isNew' in vehicle_data:
            vehicle.isNew = vehicle_data['isNew']
        if 'isBestChoice' in vehicle_data:
            vehicle.isBestChoice = vehicle_data['isBestChoice']
        if 'rating' in vehicle_data:
            vehicle.rating = vehicle_data['rating']
        if 'popularity' in vehicle_data:
            vehicle.popularity = vehicle_data['popularity']
        if 'luggage' in vehicle_data:
            vehicle.luggage = vehicle_data['luggage']
        if 'airConditioning' in vehicle_data:
            vehicle.airConditioning = vehicle_data['airConditioning']
        if 'bluetooth' in vehicle_data:
            vehicle.bluetooth = vehicle_data['bluetooth']
        
        # Sauvegarde les modifications
        db.commit()
        db.refresh(vehicle)  # Rafraîchit avec les nouvelles valeurs
        
        # Retourne les détails complets du véhicule mis à jour
        return {
            "success": True,
            "message": "Véhicule mis à jour avec succès",
            "vehicle": {
                "id": vehicle.id,
                "name": vehicle.name,
                "category": vehicle.category,
                "price": float(vehicle.price) if vehicle.price else 0.0,
                "image": vehicle.image,
                "transmission": vehicle.transmission,
                "seats": vehicle.seats,
                "engine": vehicle.engine,
                "year": vehicle.year,
                "fuel": vehicle.fuel,
                "isAvailable": vehicle.isAvailable,
                "isNew": vehicle.isNew,
                "isBestChoice": vehicle.isBestChoice,
                "rating": float(vehicle.rating) if vehicle.rating else 0.0,
                "popularity": vehicle.popularity,
                "luggage": vehicle.luggage,
                "airConditioning": vehicle.airConditioning,
                "bluetooth": vehicle.bluetooth
            }
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"Erreur lors de la mise à jour: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

# ========================================
# ENDPOINTS POUR LES CONVERSATIONS (CHAT)
# ========================================

@app.post("/conversations/", response_model=ConversationResponse, status_code=status.HTTP_201_CREATED)
def create_conversation(
    conversation_data: ConversationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Crée un nouvel objet Conversation
        new_conversation = Conversation(
            user_id=current_user.id,  # Associe à l'utilisateur courant
            title=conversation_data.title  # Utilise le titre fourni ou la valeur par défaut
        )
        
        # Ajoute et sauvegarde la conversation
        db.add(new_conversation)
        db.commit()
        db.refresh(new_conversation)
        
        # Retourne la conversation créée (automatiquement convertie par response_model)
        return new_conversation
    
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la création de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/conversations/", response_model=List[ConversationListResponse])
def get_user_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    include_inactive: bool = False  # Paramètre optionnel pour inclure les conversations inactives
):
   
    try:
        # Construction de la requête de base
        query = db.query(Conversation).filter(Conversation.user_id == current_user.id)
        
        # Filtre par statut actif si le paramètre est False
        if not include_inactive:
            query = query.filter(Conversation.is_active == True)
        
        # Exécute la requête avec tri par date de mise à jour (plus récentes d'abord)
        conversations = query.order_by(Conversation.updated_at.desc()).all()
        
        # Prépare la réponse avec des métadonnées supplémentaires
        result = []
        for conv in conversations:
            # Compte les messages dans la conversation
            message_count = len(conv.messages)
            # Récupère le dernier message (si existant)
            last_message = conv.messages[-1].content if conv.messages else None
            
            result.append({
                "id": conv.id,
                "title": conv.title,
                "created_at": conv.created_at,
                "updated_at": conv.updated_at,
                "message_count": message_count,
                "last_message": last_message
            })
        
        return result
    
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des conversations: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/conversations/{conversation_id}", response_model=ConversationResponse)
def get_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    try:
        # Recherche la conversation avec vérification de propriété
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id  # Sécurité : vérifie l'appartenance
        ).first()
        
        # Vérifie si la conversation existe
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Retourne la conversation complète avec ses messages
        return conversation
    
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"❌ Erreur lors de la récupération de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.post("/conversations/{conversation_id}/messages", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def add_message(
    conversation_id: int,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Crée le nouveau message
        new_message = Message(
            conversation_id=conversation_id,
            content=message_data.content,
            is_user=message_data.is_user  # True pour utilisateur, False pour assistant
        )
        
        db.add(new_message)
        
        # Met à jour la date de modification de la conversation
        conversation.updated_at = datetime.now()
        
        db.commit()
        db.refresh(new_message)
        
        return new_message
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de l'ajout du message: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.put("/conversations/{conversation_id}", response_model=ConversationResponse)
def update_conversation(
    conversation_id: int,
    title: str,  # Nouveau titre fourni comme paramètre de requête
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Met à jour le titre
        conversation.title = title
        conversation.updated_at = datetime.now()  # Met à jour la date de modification
        
        db.commit()
        db.refresh(conversation)
        
        return conversation
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la mise à jour de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.delete("/conversations/{conversation_id}")
def delete_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Suppression logique (au lieu de suppression physique)
        conversation.is_active = False
        db.commit()
        
        return {
            "success": True,
            "message": "Conversation supprimée avec succès"
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la suppression de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.delete("/conversations/{conversation_id}/messages/{message_id}")
def delete_message(
    conversation_id: int,
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Vérifie que le message existe dans cette conversation
        message = db.query(Message).filter(
            Message.id == message_id,
            Message.conversation_id == conversation_id
        ).first()
        
        if not message:
            raise HTTPException(
                status_code=404, 
                detail="Message non trouvé dans cette conversation"
            )
        
        # Supprime le message
        db.delete(message)
        
        # Met à jour la date de modification de la conversation
        conversation.updated_at = datetime.now()
        
        db.commit()
        
        return {
            "success": True,
            "message": "Message supprimé avec succès"
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la suppression du message: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/conversations/{conversation_id}/export")
def export_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
  
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # Prépare les données d'export au format structuré
        export_data = {
            "conversation_id": conversation.id,
            "title": conversation.title,
            "created_at": conversation.created_at.isoformat(),  # Format ISO standard
            "messages": [
                {
                    "sender": "user" if msg.is_user else "assistant",  # Étiquette lisible
                    "content": msg.content,
                    "timestamp": msg.created_at.isoformat()
                }
                for msg in conversation.messages  # Parcourt tous les messages
            ]
        }
        
        return export_data
    
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"❌ Erreur lors de l'export de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

# ========================================
# FONCTION DE GÉNÉRATION DE RÉPONSE POUR L'ASSISTANT
# ========================================

def generate_assistant_response(user_message: str, current_user: User, db: Session) -> str:
    # Convertit le message en minuscules pour une comparaison insensible à la casse
    user_message_lower = user_message.lower()
    
    # Récupère les données contextuelles de l'utilisateur
    user_bookings = db.query(Booking).filter(Booking.user_id == current_user.id).all()
    user_favorites = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    available_cars = db.query(vehicles).filter(vehicles.isAvailable == True).count()
    all_cars = db.query(vehicles).all()
    
    # ========================================
    # RÉPONSES PRÉDÉFINIES POUR LES QUESTIONS COURANTES
    # ========================================
    
    # Question : Comment réserver ?
    if user_message_lower == "comment réserver ?" or "réserver" in user_message_lower and "comment" in user_message_lower:
        return """📋 **Comment réserver un véhicule :**
        
1. **Parcourez** notre catalogue de véhicules dans l'onglet "Nos voitures"
2. **Sélectionnez** le véhicule qui vous convient
3. **Cliquez** sur le bouton "Réserver" (vert si disponible)
4. **Remplissez** le formulaire avec :
   - Vos informations personnelles
   - Les dates de location
   - L'heure et le lieu de prise
   - Les options supplémentaires
5. **Confirmez** la réservation

💰 **Paiement :** Le paiement se fait à la prise du véhicule, ou en ligne selon l'option choisie.
📞 **Besoin d'aide ?** Contactez-nous au 71 234 567"""
    
    # Question : Quels sont les tarifs ?
    elif user_message_lower == "quels sont les tarifs ?" or "tarifs" in user_message_lower or "prix" in user_message_lower:
        # Calcule les prix moyens par catégorie
        categories = {}
        # On parcourt tous les objets "car" dans la liste all_cars
        for car in all_cars:
             # On récupère la catégorie de la voiture (ex: 'SUV', 'Citadine', 'Berline')
            cat = car.category
            # Si cette catégorie n'existe pas encore dans le dictionnaire "categories", on l'initialise avec une liste vide
            if cat not in categories:
                categories[cat] = []
                 # On ajoute le prix de la voiture dans la liste correspondant à sa catégorie
    # On convertit le prix en float au cas où il serait stocké comme chaîne de caractères
            categories[cat].append(float(car.price))
        
        # Construit la réponse avec les informations de prix
        price_info = "💵 **Tarifs par catégorie (par jour) :**\n\n"
        for cat, prices in categories.items():
            if prices:
                avg = sum(prices) / len(prices)
                price_info += f"• **{cat}** : {avg:.0f} - {max(prices):.0f} TND\n"
        
        price_info += "\n💡 **Informations supplémentaires :**\n"
        price_info += "• Location de plusieurs jours : réduction de 10% à partir de 3 jours\n"
        price_info += "• Options supplémentaires :\n"
        price_info += "  - Chauffeur : +50 TND/jour\n"
        price_info += "  - GPS : +5 TND/jour\n"
        price_info += "  - Siège enfant : +3 TND/jour\n"
        price_info += "\n🔍 Pour connaître le prix exact d'un véhicule, consultez sa fiche détaillée."
        
        return price_info
    
    # Question : Ajouter aux favoris
    elif user_message_lower == "ajouter aux favoris" or "favoris" in user_message_lower and "ajouter" in user_message_lower:
        favorite_count = len(user_favorites)
        if favorite_count > 0:
            # Récupère les noms des derniers véhicules favoris
            car_names = []
            for fav in user_favorites[:3]:  # Limite à 3 noms pour la lisibilité
                car = db.query(vehicles).filter(vehicles.id == fav.car_id).first()
                if car:
                    car_names.append(car.name)
            
            # Formate la liste des noms
            cars_list = ", ".join(car_names)
            if favorite_count > 3:
                cars_list += f" et {favorite_count - 3} autres"
            
            return f"""❤️ **Vos favoris :**
            
Vous avez actuellement **{favorite_count} véhicule(s)** dans vos favoris.
Derniers ajouts : {cars_list}

**Pour ajouter un véhicule aux favoris :**
1. Allez dans "Nos voitures"
2. Trouvez un véhicule qui vous plaît
3. Cliquez sur l'icône ❤️ en haut à droite de l'image
4. Le véhicule sera ajouté à votre liste

📱 **Accès rapide :** Retrouvez tous vos favoris dans l'onglet "Mes Favoris" du menu principal."""
        else:
            return """❤️ **Ajouter aux favoris :**
            
**Pour ajouter un véhicule aux favoris :**
1. Naviguez dans notre catalogue de véhicules
2. Lorsque vous trouvez un véhicule qui vous intéresse
3. Cliquez sur l'icône ❤️ (cœur) en haut à droite de la photo du véhicule
4. Le véhicule sera sauvegardé dans votre liste personnelle

💡 **Utilité des favoris :**
• Gardez une trace des véhicules qui vous plaisent
• Comparez facilement plusieurs modèles
• Accédez rapidement à vos préférés
• Recevez des notifications si le prix baisse

🎯 **Conseil :** Ajoutez plusieurs véhicules pour comparer et choisir plus facilement !"""
    
    # Question : Types de véhicules
    elif user_message_lower == "types de véhicules" or "catégories" in user_message_lower:
        # Compte les véhicules par catégorie
        category_counts = {}
        category_examples = {}
        
        for car in all_cars:
            cat = car.category
            if cat not in category_counts:
                category_counts[cat] = 0
                category_examples[cat] = car.name
            category_counts[cat] += 1
        
        # Construit la réponse détaillée
        response = "🚗 **Nos catégories de véhicules :**\n\n"
        for cat, count in category_counts.items():
            example = category_examples.get(cat, "")
            response += f"• **{cat}** ({count} modèles)\n"
            response += f"  *Exemple : {example}*\n"
            response += f"  *Idéal pour : "
            
            # Ajoute une description contextuelle par catégorie
            if cat == "Économique":
                response += "petits budgets, ville*\n"
            elif cat == "Citadine":
                response += "ville, petits trajets*\n"
            elif cat == "Familiale":
                response += "familles, grands espaces*\n"
            elif cat == "Compacte":
                response += "confort urbain*\n"
            elif cat == "SUV":
                response += "aventure, tout-terrain*\n"
            else:
                response += "usage général*\n"
        
        # Ajoute des conseils de choix
        response += "\n🔍 **Comment choisir ?**\n"
        response += "• Pour la ville : Économique ou Citadine\n"
        response += "• Pour la famille : Familiale ou SUV\n"
        response += "• Pour le confort : Compacte\n"
        response += "• Pour les voyages : SUV\n"
        
        return response
    
    # Question : Contacter le support
    elif user_message_lower == "contacter le support" or "support" in user_message_lower:
        return """📞 **Contact et support :**
        
**Service client disponible :**
• 📞 Téléphone : (+216) 71 234 567
• 📧 Email : support@carrental-tn.com
• 🌐 Site web : www.carrental-tn.com

**Horaires d'ouverture :**
• Lundi - Vendredi : 8h00 - 18h00
• Samedi : 9h00 - 16h00
• Dimanche : Fermé

**Points de contact :**
• **Réservations :** reservation@carrental-tn.com
• **Support technique :** tech@carrental-tn.com
• **Réclamations :** reclamation@carrental-tn.com

**Agences physiques :**
1. **Tunis Centre** : Avenue Habib Bourguiba
2. **Aéroport Tunis-Carthage** : Hall des arrivées
3. **Sousse** : Rue Habib Thameur
4. **Sfax** : Avenue de la République

💡 **Conseil :** Pour une réponse rapide, appelez-nous pendant les heures d'ouverture."""
    
    # Question : Véhicules disponibles
    elif user_message_lower == "véhicules disponibles" or "disponibles" in user_message_lower:
        # Récupère quelques véhicules disponibles
        available_cars_list = db.query(vehicles).filter(
            vehicles.isAvailable == True
        ).limit(5).all()  # Limite à 5 résultats
        
        response = f"✅ **Véhicules disponibles :**\n\n"
        response += f"Nous avons actuellement **{available_cars} véhicules** disponibles à la location.\n\n"
        
        if available_cars_list:
            response += "**Quelques modèles disponibles :**\n"
            for car in available_cars_list:
                response += f"• **{car.name}** ({car.category}) - {float(car.price):.0f} TND/jour\n"
            
            response += f"\n💡 **Conseil :** {available_cars} choix disponibles. Réservez vite pour garantir votre véhicule préféré !\n"
        else:
            response += "Aucun véhicule disponible pour le moment.\n"
        
        # Informations sur les filtres disponibles
        response += "\n**Filtres disponibles :**\n"
        response += "• Par prix (0 - 500 TND)\n"
        response += "• Par catégorie (Économique, SUV...)\n"
        response += "• Par disponibilité\n"
        response += "• Par nombre de places\n"
        
        response += "\n🔍 **Comment voir tous les véhicules ?**\n"
        response += "Allez dans 'Nos voitures' et utilisez les filtres pour trouver le véhicule parfait !"
        
        return response
    
    # Question : Modifier mon profil
    elif user_message_lower == "modifier mon profil" or "profil" in user_message_lower and ("modifier" in user_message_lower or "changer" in user_message_lower):
        return """👤 **Modifier votre profil :**
        
**Pour modifier vos informations personnelles :**
1. Allez dans l'onglet "Mon Profil" (icône 👤)
2. Cliquez sur la section "Modifier mon compte"
3. Vous pouvez modifier :
   • Votre nom d'utilisateur
   • Votre adresse email
   • Votre mot de passe

**Informations modifiables :**
• **Nom d'utilisateur** : Votre identifiant d'affichage
• **Email** : Adresse de connexion et de contact
• **Mot de passe** : Sécurité de votre compte

⚠️ **Important :**
• Pour changer le mot de passe, vous devez connaître l'actuel
• Après modification d'email, vous devrez utiliser le nouvel email pour vous reconnecter
• Les modifications sont immédiates

🔒 **Sécurité :**
Vos données sont cryptées et protégées selon les normes RGPD.

💡 **Besoin d'aide ?** Contactez le support si vous rencontrez des difficultés."""
    
    # ========================================
    # RÉPONSES GÉNÉRALES BASÉES SUR LES MOTS-CLÉS
    # ========================================
    
    # Salutations
    elif any(word in user_message_lower for word in ['bonjour', 'salut', 'hello', 'hi', 'coucou']):
        return f"Bonjour {current_user.username} ! 👋 Je suis votre assistant CarRental. Comment puis-je vous aider aujourd'hui ?"
    
    # Réservations
    elif any(word in user_message_lower for word in ['réservation', 'réserver', 'louer']):
        if user_bookings:
            # Filtre les réservations actives
            active_bookings = [b for b in user_bookings if b.status in ["Confirmée", "En attente"]]
            if active_bookings:
                return f"Vous avez {len(active_bookings)} réservation(s) active(s). Allez dans 'Mes Réservations' pour les gérer."
        return "Pour réserver, allez dans 'Nos voitures', choisissez un véhicule et cliquez sur 'Réserver'."
    
    # Annulations
    elif any(word in user_message_lower for word in ['annuler', 'annulation', 'supprimer']):
        if user_bookings:
            return "Pour annuler une réservation, allez dans 'Mes Réservations', trouvez la réservation et contactez le support."
        return "Vous n'avez aucune réservation à annuler."
    
    # Remerciements
    elif any(word in user_message_lower for word in ['merci', 'thanks', 'thank you']):
        return "Je vous en prie ! N'hésitez pas si vous avez d'autres questions. 😊"
    
    # ========================================
    # RÉPONSE PAR DÉFAUT (QUESTION NON RECONNUE)
    # ========================================
    else:
        # Réponse générique avec suggestions
        default_responses = [
            "Je comprends que vous dites : '{}'\n\nVoici ce que je peux vous aider :".format(user_message),
            "• Réserver un véhicule 📅",
            "• Consulter mes favoris ❤️",
            "• Vérifier mes réservations 📋",
            "• Connaître les tarifs 💰",
            "• Contacter le support 📞",
            "• Voir les véhicules disponibles 🚗",
            "• Modifier mon profil 👤",
            "\nPosez-moi une question plus précise ou utilisez les suggestions ci-dessous !"
        ]
        return "\n".join(default_responses)

# ========================================
# ENDPOINT PRINCIPAL POUR L'ASSISTANT DE CHAT
# ========================================

@app.post("/assistant/chat")
async def chat_with_assistant(
    data: ChatInput, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Vérifie que la conversation existe et appartient à l'utilisateur
        conversation = db.query(Conversation).filter(
            Conversation.id == data.conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        
        if not conversation:
            raise HTTPException(
                status_code=404, 
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        
        # 1. Sauvegarde le message de l'utilisateur
        user_msg = Message(
            conversation_id=data.conversation_id,
            content=data.content,
            is_user=True
        )
        db.add(user_msg)
        
        # 2. Génère une réponse intelligente via la fonction d'assistance
        bot_reply = generate_assistant_response(data.content, current_user, db)
        
        # 3. Sauvegarde la réponse de l'assistant
        assistant_msg = Message(
            conversation_id=data.conversation_id,
            content=bot_reply,
            is_user=False  # Message du système/assistant
        )
        db.add(assistant_msg)
        
        # Met à jour la date de modification de la conversation
        conversation.updated_at = datetime.now()
        
        # Valide toutes les modifications en une seule transaction
        db.commit()
        # Rafraîchit les objets pour obtenir leurs IDs générés
        db.refresh(user_msg)
        db.refresh(assistant_msg)
        
        # Retourne une réponse complète avec métadonnées
        return {
            "success": True,
            "reply": bot_reply,  # La réponse générée
            "user_message_id": user_msg.id,  # ID du message utilisateur sauvegardé
            "assistant_message_id": assistant_msg.id,  # ID du message assistant sauvegardé
            "conversation_id": data.conversation_id  # ID de la conversation
        }
    
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()  # Annule la transaction en cas d'erreur
        print(f"❌ Erreur lors de l'interaction avec l'assistant: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

