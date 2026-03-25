# ========================================
# IMPORTATION DES MODULES NÉCESSAIRES
# ========================================

# Importation de FastAPI pour créer l'application web et gérer les requêtes HTTP
# Depends permet d’injecter automatiquement des dépendances (comme des services ou fonctions) dans les routes FastAPI
from fastapi import FastAPI, HTTPException, Depends, status, Form, Request, UploadFile, File

# Middleware pour gérer le CORS (Cross-Origin Resource Sharing) - permet à d'autres domaines d'accéder à l'API
from fastapi.middleware.cors import CORSMiddleware

# Pour servir des fichiers statiques (images, CSS, etc.) depuis un dossier
from fastapi.staticfiles import StaticFiles

# Modèles Pydantic pour la validation des données reçues et envoyées
from pydantic import BaseModel, EmailStr

# Session de base de données SQLAlchemy
from sqlalchemy.orm import Session

# Bibliothèque bcrypt pour le hachage et la vérification des mots de passe
import bcrypt

# Importation des modèles SQLAlchemy définis dans le fichier models.py
from models import User, Admin, vehicles, Favorite, Booking, Conversation, Message, Base, engine, SessionLocal
# Le module typing permet d’indiquer des types dans Python 
# Types optionnels et listes pour les annotations de type
from typing import Optional, List

# Modules pour la gestion des dates et heures
from datetime import datetime, timedelta, date

# Bibliothèque JWT pour créer et vérifier les tokens d'authentification
# jose est une bibliothèque utilisée pour créer, signer et vérifier les tokens JWT
# JWTError représente une erreur liée à la validation d’un token JWT
from jose import JWTError, jwt

# Schéma OAuth2 pour l'authentification par token
# OAuth2PasswordBearer sert à extraire le token d’accès d’une requête pour la sécurisation d’API
#OAuth2PasswordRequestForm gère la récupération des champs username et password lors de l’authentification via OAuth2.
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

# Réponse JSON personnalisée
from fastapi.responses import JSONResponse

# os est un module Python qui permet d’interagir avec le système d’exploitation
import os
# shutil est un module Python utilisé pour effectuer des opérations de haut niveau sur les fichiers et dossiers
import shutil

# Génération d'identifiants uniques pour les noms de fichiers uploadés
import uuid

# ========================================
# CONFIGURATION JWT
# ========================================
## secrets est un module Python utilisé pour générer des valeurs aléatoires sécurisées
# Clé secrète utilisée pour signer les tokens JWT obtenue d'apres le code:
#import secrets
#SECRET_KEY = secrets.token_hex(32)
#print(SECRET_KEY)
SECRET_KEY = "a1d03237d6435d1d39ab8047118d622c314024ca04b478877a13e8ae238674d1"

# Algorithme de chiffrement pour JWT
ALGORITHM = "HS256"

# Durée d'expiration du token en minutes
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ========================================
# INITIALISATION DE LA BASE DE DONNÉES
# ========================================
# Crée toutes les tables définies dans les modèles SQLAlchemy si elles n'existent pas déjà
Base.metadata.create_all(bind=engine)

# ========================================
# INITIALISATION DE L'APPLICATION FASTAPI
# ========================================
# Crée une instance de l'application FastAPI avec un titre et une version
app = FastAPI(title="API", version="1.0.0")

# ========================================
# CONFIGURATION DU DOSSIER D'IMAGES UPLOADÉES
# ========================================
# Définit le dossier où seront stockées les images uploadées
UPLOAD_FOLDER = "static/images"

# Crée le dossier s'il n'existe pas (exist_ok=True évite une erreur si le dossier existe déjà)
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Monte le dossier "static" pour qu'il soit accessible via l'URL /static
app.mount("/static", StaticFiles(directory="static"), name="static")

# ========================================
# CONFIGURATION CORS
# ========================================
# Ajoute le middleware CORS à l'application.
# on utilise allow_origin_regex pour autoriser dynamiquement TOUS les
# ports localhost (Flutter Web change de port à chaque `flutter run`, ex: 57217, 64320...).
# En production,on remplace allow_origin_regex par allow_origins avec l'URL exacte du domaine.
app.add_middleware(
    CORSMiddleware,
    # accepte tous les ports localhost (Flutter Web, React, etc.) ---
    allow_origin_regex=r"http://localhost(:\d+)?",  # ex: localhost:57217, localhost:3000…
    allow_credentials=True,  # Autorise l'envoi de cookies/credentials
    allow_methods=["*"],      # Autorise toutes les méthodes HTTP
    allow_headers=["*"],      # Autorise tous les en-têtes
)

# ========================================
# FONCTIONS UTILITAIRES DE BASE DE DONNÉES
# ========================================
def get_db():
    """
    Dépendance FastAPI pour obtenir une session de base de données.
    """
    db = SessionLocal()  # Crée une nouvelle session
    try:
        yield db  # Fournit la session à la route
    finally:
        db.close()  # Ferme la session après utilisation

# ========================================
# FONCTIONS UTILITAIRES DE SÉCURITÉ
# ========================================
def hash_password(password: str) -> str:
    """
    Hache un mot de passe en clair avec bcrypt.
    """
    # encode le mot de passe en bytes, génère un sel et hache, puis retourne le hash en string
    ## UTF-8 est un encodage de caractères qui permet de représenter et d’afficher correctement les textes
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    """
    Vérifie si un mot de passe en clair correspond à un hash bcrypt.
    """
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

def user_response(user: User):
    """
    Transforme un objet User en dictionnaire sérialisable (sans le mot de passe).
    """
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "role": user.role,
        # isoformat() permet de convertir une date ou un datetime en une chaîne de caractères au format standard ISO
        "created_at": user.created_at.isoformat() if user.created_at else None
    }

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """
    Crée un token JWT avec une date d'expiration.
    """
    to_encode = data.copy()  # Copie les données pour ne pas modifier l'original
    if expires_delta:
        expire = datetime.utcnow() + expires_delta  # Expiration personnalisée
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)  # Expiration par défaut
    to_encode.update({"exp": expire})  # Ajoute le champ "exp"
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)  # Encode et retourne le token

# ========================================
# MODÈLES PYDANTIC POUR LA VALIDATION
# ========================================
class UserRegister(BaseModel):
    """
    Schéma de validation pour l'inscription d'un utilisateur.
    """
    username: str
    email: EmailStr  # Valide que l'email a un format correct
    password: str

class ResetPassword(BaseModel):
    """
    Schéma pour la réinitialisation du mot de passe.

    """
    email: EmailStr
    new_password: str
    confirm_password: str  

class FavoriteRequest(BaseModel):
    """
    Schéma pour ajouter un favori (contient l'ID de la voiture).
    """
    car_id: int

class BookingCreate(BaseModel):
    """
    Schéma pour créer une réservation.
    """
    car_id: int
    full_name: str
    pickup_date: str 
    return_date: str
    total_price: float

class UpdateProfileRequest(BaseModel):
    """
    Schéma pour la mise à jour du profil utilisateur.
    """
    username: Optional[str] = None
    email: Optional[str] = None
    current_password: Optional[str] = None
    new_password: Optional[str] = None

class ConversationCreate(BaseModel):
    """
    Schéma pour créer une nouvelle conversation (titre optionnel).
    """
    title: Optional[str] = "Nouvelle conversation"

class MessageCreate(BaseModel):
    """
    Schéma pour créer un message dans une conversation.
    """
    content: str
    is_user: bool = True  # True si c'est l'utilisateur qui envoie, False si c'est l'assistant

class MessageResponse(BaseModel):
    """
    Schéma de réponse pour un message.
    """
    id: int
    conversation_id: int
    content: str
    is_user: bool
    created_at: datetime
    class Config:
        from_attributes = True

class ConversationResponse(BaseModel):
    """
    Schéma de réponse pour une conversation (avec ses messages).
    """
    id: int
    user_id: int
    title: str
    created_at: datetime
    updated_at: datetime
    is_active: bool
    messages: List[MessageResponse] = []  # Liste des messages de la conversation
    # Config avec from_attributes = True permet à Pydantic de créer le modèle à partir d’un objet (comme un objet SQLAlchemy) en lisant directement ses attributs.
    class Config:
        from_attributes = True

class ConversationListResponse(BaseModel):
    """
    Schéma de réponse pour la liste des conversations .
    """
    id: int
    title: str
    created_at: datetime
    updated_at: datetime
    #calcule ensuite
    message_count: int  # Nombre de messages dans la conversation
    last_message: Optional[str] = None  # Contenu du dernier message
    class Config:
        from_attributes = True

class ChatInput(BaseModel):
    """
    Schéma pour envoyer un message à l'assistant dans une conversation existante.
    """
    conversation_id: int
    content: str

# ========================================
# CONFIGURATION OAUTH2
# ========================================
# Définit le point de terminaison pour obtenir le token (utilisé par la dépendance OAuth2)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# ========================================
# ENDPOINTS D'AUTHENTIFICATION
# ========================================
@app.post("/register", status_code=status.HTTP_201_CREATED)
def register(user: UserRegister, db: Session = Depends(get_db)):
    """
    Endpoint d'inscription d'un nouvel utilisateur.
    """
    # Vérifie si un utilisateur avec cet email existe déjà
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        # status_code=400 indique que la requête est invalide
        raise HTTPException(status_code=400, detail="Email déjà utilisé")
    # Crée un nouvel utilisateur avec le mot de passe hashé
    new_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hash_password(user.password)
    )
    db.add(new_user)  # Ajoute à la session
    db.commit()  # Valide la transaction
    db.refresh(new_user)  # Rafraîchit l'objet pour obtenir l'ID généré
    return {
        "message": "Inscription réussie",
        "user": user_response(new_user)  # Retourne les infos de l'utilisateur sans mot de passe
    }

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Endpoint de connexion. Utilise le formulaire OAuth2 (username/password).
    Le champ username peut être soit l'email soit le nom d'utilisateur.
    """
    # Recherche un utilisateur par email OU par nom d'utilisateur
    db_user = db.query(User).filter(
        (User.email == form_data.username) | (User.username == form_data.username)
    ).first()
    # Vérifie l'existence et le mot de passe
    if not db_user or not verify_password(form_data.password, db_user.hashed_password):
        # status_code=401 indique que l’accès est non autorisé
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    # Crée un token JWT avec l'email et le rôle
    access_token = create_access_token(data={"sub": db_user.email, "role": db_user.role})

    # -------------------------------------------------------
    # SYNCHRONISATION AVEC LA TABLE "admins"
    # -------------------------------------------------------
    # Si l'utilisateur est admin, on s'assure qu'il est bien présent
    # dans la table "admins" avec tous ses attributs à jour.
    if db_user.role == "admin":
        existing_admin = db.query(Admin).filter(Admin.user_id == db_user.id).first()
        if not existing_admin:
            # L'admin n'est pas encore dans la table admins → on l'ajoute avec tous ses attributs
            new_admin = Admin(
                user_id=db_user.id,
                username=db_user.username,
                email=db_user.email,
                hashed_password=db_user.hashed_password,
                role=db_user.role,
                is_active=db_user.is_active,
                created_at=db_user.created_at
            )
            db.add(new_admin)
            db.commit()
            print(f"✅ Admin '{db_user.username}' ajouté dans la table admins")

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user_response(db_user)
    }

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Dépendance pour obtenir l'utilisateur courant à partir du token JWT.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # Décode le token JWT
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    # Récupère l'utilisateur correspondant dans la base de données
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

@app.post("/forgot-password/reset")
def reset_password(data: ResetPassword, db: Session = Depends(get_db)):
    """
    Endpoint pour réinitialiser le mot de passe.
    """
    # -------------------------------------------------------
    #vérification que les deux mots de passe correspondent
    # -------------------------------------------------------
    if data.new_password != data.confirm_password:
        raise HTTPException(
            status_code=400,
            detail="Les mots de passe ne correspondent pas"
        )

    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        # status_code=404 indique que la ressource demandée est introuvable
        raise HTTPException(status_code=404, detail="Aucun compte associé à cet email")

    # Hache le nouveau mot de passe
    new_hashed = hash_password(data.new_password)

    # 1. Met à jour le mot de passe dans la table 'users'
    user.hashed_password = new_hashed

    # 2. Si c'est un admin, synchronise aussi la table 'admins'
    if user.role == "admin":
        admin_entry = db.query(Admin).filter(Admin.user_id == user.id).first()
        if admin_entry:
            admin_entry.hashed_password = new_hashed
            print(f"✅ Mot de passe synchronisé dans admins pour '{user.username}'")

    db.commit()
    return {"message": "Mot de passe réinitialisé avec succès"}

# ========================================
# ENDPOINTS POUR LES VÉHICULES
# ========================================
@app.get("/vehicles")
def get_vehicles(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Récupère la liste de tous les véhicules avec l'information si chacun est en favori de l'utilisateur courant.
    """
    # Récupère tous les véhicules
    vehicles_list = db.query(vehicles).all()
    # Récupère les IDs des favoris de l'utilisateur courant
    user_favorites = db.query(Favorite.car_id).filter(Favorite.user_id == current_user.id).all()
    favorite_ids = [fav.car_id for fav in user_favorites]
    # Construit la liste de réponse avec les champs nécessaires
    return [
        {
            "id": v.id,
            "name": v.name,
            "category": v.category,
            "price": float(v.price) if v.price else 0.0,
            "image": v.image,
            "transmission": v.transmission,
            "seats": v.seats,
            "engine": v.engine,
            "year": v.year,
            "fuel": v.fuel,
            "isAvailable": v.isAvailable,
            ## Vérifie si l’ID du véhicule fait partie de la liste des favoris de l’utilisateur (True si oui, False sinon)
            "isFavorite": v.id in favorite_ids,
            "isNew": v.isNew,
            "isBestChoice": v.isBestChoice,
            "rating": float(v.rating) if v.rating else 0.0,
            "popularity": v.popularity,
            "luggage": v.luggage,
            "airConditioning": v.airConditioning,
            "bluetooth": v.bluetooth
        }
        # Parcourt chaque véhicule (v) dans la liste vehicles_list
        for v in vehicles_list
    ]

# ========================================
# ENDPOINTS POUR LES FAVORIS
# ========================================
@app.get("/favorites")
def get_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Récupère la liste des véhicules favoris de l'utilisateur courant.
    """
    # Récupère toutes les entrées de favoris de l'utilisateur
    favorites = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    favorite_cars = []
    for fav in favorites:
        # Pour chaque favori, récupère les détails du véhicule
        car = db.query(vehicles).filter(vehicles.id == fav.car_id).first()
        if car:
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
                "isFavorite": True,
                "isNew": car.isNew,
                "isBestChoice": car.isBestChoice,
                "rating": float(car.rating) if car.rating else 0.0,
                "popularity": car.popularity,
                "luggage": car.luggage,
                "airConditioning": car.airConditioning,
                "bluetooth": car.bluetooth
            })
    return favorite_cars

@app.post("/favorites/add")
def add_favorite(favorite: FavoriteRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Ajoute un véhicule aux favoris de l'utilisateur.
    """
    # Vérifie que le véhicule existe
    car = db.query(vehicles).filter(vehicles.id == favorite.car_id).first()
    if not car:
        raise HTTPException(status_code=404, detail="Véhicule non trouvé")
    # Vérifie que ce favori n'existe pas déjà
    existing_favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.car_id == favorite.car_id
    ).first()
    if existing_favorite:
        raise HTTPException(status_code=400, detail="Déjà dans les favoris")
    # Crée un nouveau favori
    new_favorite = Favorite(
        user_id=current_user.id,
        car_id=favorite.car_id
    )
    db.add(new_favorite)
    db.commit()
    return {"message": "Ajouté aux favoris avec succès"}

@app.delete("/favorites/remove/{car_id}")
def remove_favorite(car_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Supprime un véhicule des favoris de l'utilisateur.
    """
    # Recherche le favori correspondant
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.car_id == car_id
    ).first()
    if not favorite:
        raise HTTPException(status_code=404, detail="Favori non trouvé")
    # Supprime le favori
    db.delete(favorite)
    db.commit()
    return {"message": "Retiré des favoris avec succès"}

# ========================================
# ENDPOINTS POUR LES RÉSERVATIONS
# ========================================
@app.post("/bookings", response_model=dict)
def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Crée une nouvelle réservation pour l'utilisateur courant.
    """
    try:
        # Convertit les chaînes de date en objets date
        try:
            # Le .date() extrait uniquement la **partie date** d’un objet datetime (année, mois, jour) en supprimant l’heure et les minutes.
            pickup_date = datetime.strptime(booking_data.pickup_date, "%Y-%m-%d").date()
            return_date = datetime.strptime(booking_data.return_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Format de date invalide. Utilisez YYYY-MM-DD")
        # Vérifie que la voiture existe
        car = db.query(vehicles).filter(vehicles.id == booking_data.car_id).first()
        if not car:
            raise HTTPException(status_code=404, detail="Voiture non trouvée")
        # Vérifie la disponibilité
        if not car.isAvailable:
            raise HTTPException(status_code=400, detail="Cette voiture n'est pas disponible")
        # Vérifie que la date de retour est postérieure à la date de prise en charge
        if return_date <= pickup_date:
            raise HTTPException(
                status_code=400,
                detail=f"La date de retour ({return_date}) doit être après la date de prise en charge ({pickup_date})"
            )
        # Recherche dans la base une réservation qui se chevauche avec les nouvelles dates
        overlapping_booking = db.query(Booking).filter(
               # Filtre sur le véhicule concerné
            Booking.car_id == booking_data.car_id,
             # Ne prend en compte que les réservations actives (en attente ou confirmées)
            Booking.status.in_(["En attente", "Confirmée"]),
            # Vérifie que la réservation existante commence avant la fin de la nouvelle réservation
            Booking.pickup_date < return_date,   
             # Vérifie que la réservation existante se termine après le début de la nouvelle réservation
            Booking.return_date > pickup_date   
        ).first()

        if overlapping_booking:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Ce véhicule est déjà réservé du {overlapping_booking.pickup_date} "
                    f"au {overlapping_booking.return_date}. "
                    "Veuillez choisir d'autres dates."
                )
            )
        # -------------------------------------------------------
        # Crée la réservation avec le statut "En attente"
        new_booking = Booking(
            user_id=current_user.id,
            car_id=booking_data.car_id,
            full_name=booking_data.full_name,
            pickup_date=pickup_date,
            return_date=return_date,
            total_price=booking_data.total_price,
            status="En attente"
        )
        db.add(new_booking)
        db.commit()
        db.refresh(new_booking)
        # Si la réservation commence aujourd'hui ou avant, marque la voiture comme non disponible
        # Permet d’utiliser un alias(nom alternatif) "date_class" pour représenter la classe datetime.date et éviter les conflits de nom avec d’autres variables.
        from datetime import date as date_class
        if pickup_date <= date_class.today():
            car.isAvailable = False
            db.commit()
        return {
            "success": True,
            "message": "Réservation créée avec succès",
            "booking_id": new_booking.id,
            "status": new_booking.status
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()  # Annule toutes les modifications en base de données en cas d’erreur
        print(f"Erreur lors de la création de la réservation: {e}")
        # status_code=500 indique une erreur interne du serveur
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/my-bookings")
def get_user_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Récupère toutes les réservations de l'utilisateur courant, triées par date de création descendante.
    """
    try:
        bookings = db.query(Booking).filter(
            Booking.user_id == current_user.id
        ).order_by(Booking.created_at.desc()).all()
        result = []
        for booking in bookings:
            car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
            # append permet d’ajouter un élément à la fin d’une liste.
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
# FONCTIONS ADMINISTRATEUR
# ========================================
def get_current_admin(current_user: User = Depends(get_current_user)):
    """
    Dépendance pour vérifier que l'utilisateur courant est un administrateur.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé. Droits administrateur requis."
        )
    return current_user

# -------------------------------------------------------
# ENDPOINT : LISTE DE tous les réservations (admin seulement)
# -------------------------------------------------------
@app.get("/admin/bookings")
def get_all_bookings(
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """
    Récupère toutes les réservations (admin seulement).
    """
    try:
        bookings = db.query(Booking).order_by(Booking.created_at.desc()).all()
        result = []
        for booking in bookings:
            car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
            user = db.query(User).filter(User.id == booking.user_id).first()
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

@app.patch("/admin/bookings/{booking_id}/status")
def update_booking_status(
    booking_id: int,
    status: str,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """
    Met à jour le statut d'une réservation (admin seulement).
    """
    try:
        from datetime import date as date_class
        valid_statuses = ["En attente", "Confirmée", "Annulée", "Terminée"]
        if status not in valid_statuses:
            raise HTTPException(
                status_code=400,
                detail=f"Statut invalide. Valeurs acceptées: {', '.join(valid_statuses)}"
            )
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Réservation non trouvée")
        old_status = booking.status
        booking.status = status
        car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
        # Gestion de la disponibilité de la voiture en fonction du statut
        if car:
            if status in ["Annulée", "Terminée"]:
                # Vérifie s'il y a d'autres réservations actives sur cette voiture
                other_active_bookings = db.query(Booking).filter(
                    Booking.car_id == booking.car_id,
                    # Exclut la réservation actuelle en cours de modification (évite de se comparer à elle-même)
                    Booking.id != booking_id,
                    Booking.status.in_(["Confirmée", "En attente"]),
                    Booking.pickup_date <= date_class.today(),
                    Booking.return_date >= date_class.today()
                ).first()
                if not other_active_bookings:
                    car.isAvailable = True
            elif status == "Confirmée":
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
    """
    Supprime une réservation (admin seulement) et rend la voiture disponible si nécessaire.
    """
    try:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Réservation non trouvé")
        car = db.query(vehicles).filter(vehicles.id == booking.car_id).first()
        if car:
            car.isAvailable = True
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
@app.put("/update-profile/")
async def update_profile(
    profile_data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Met à jour le profil de l'utilisateur (nom, email, mot de passe).
    """
    try:
        print(f"📥 Données reçues: {profile_data}")
        print(f"👤 Utilisateur actuel: {current_user.username} ({current_user.email})")
        # Si un mot de passe actuel est fourni, on vérifie qu'il correspond
        if profile_data.current_password:
            if not verify_password(profile_data.current_password, current_user.hashed_password):
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Mot de passe actuel incorrect"}
                )
            print("✅ Mot de passe actuel vérifié")
        updates_made = False
        # Mise à jour du nom d'utilisateur
        if profile_data.username and profile_data.username != current_user.username:
            existing_user = db.query(User).filter(
                User.username == profile_data.username,
                User.id != current_user.id
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
            if not profile_data.current_password:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "message": "Le mot de passe actuel est requis pour changer le mot de passe"}
                )
            current_user.hashed_password = hash_password(profile_data.new_password)
            updates_made = True
            print("✅ Mot de passe mis à jour")
        if not updates_made:
            return JSONResponse(
                status_code=400,
                content={"success": False, "message": "Aucune modification détectée"}
            )
        db.commit()
        db.refresh(current_user)
        print("✅ Profil mis à jour avec succès")

        # -------------------------------------------------------
        # SYNCHRONISATION AVEC LA TABLE "admins"
        # -------------------------------------------------------
        # Si l'utilisateur est admin, on met à jour aussi ses données
        # dans la table "admins" pour garder les deux tables cohérentes.
        if current_user.role == "admin":
            admin_entry = db.query(Admin).filter(Admin.user_id == current_user.id).first()
            if admin_entry:
                # Met à jour chaque champ modifié dans admins
                admin_entry.username = current_user.username
                admin_entry.email = current_user.email
                admin_entry.hashed_password = current_user.hashed_password
                admin_entry.is_active = current_user.is_active
                db.commit()
                print(f"✅ Table admins synchronisée pour '{current_user.username}'")

        new_token = create_access_token(data={"sub": current_user.email, "role": current_user.role})
        return JSONResponse(
            status_code=200,
            content={
                "success": True,
                "message": "Profil mis à jour avec succès",
                "user": user_response(current_user),
                "new_token": new_token
            }
        )
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur serveur: {e}")
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": f"Erreur serveur: {str(e)}"}
        )

# ========================================
# ENDPOINT UPLOAD D'IMAGE
# ========================================
@app.post("/upload-image/")
async def upload_image(
    #File(...) indique que ce champ est obligatoire).
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Endpoint pour uploader une image.
    """
    try:
        # Vérification du type 
        allowed_types = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail="Type de fichier non autorisé. Utilisez JPG, PNG ou WEBP."
            )
        # Génération d'un nom de fichier unique
        #[-1] = prend la dernière partie
        ## Cette ligne récupère l’extension du fichier en séparant le nom du fichier par le point et en prenant la dernière partie.
        extension = file.filename.split(".")[-1]
        # uuid4() génère un identifiant unique aléatoire (UUID)
        unique_filename = f"{uuid.uuid4()}.{extension}"
        file_path = f"{UPLOAD_FOLDER}/{unique_filename}"
        # Sauvegarde du fichier sur le disque
        ## "wb" signifie ouvrir un fichier en mode écriture binaire
        #buffer est simplement une variable qui représente le fichier ouvert.
        with open(file_path, "wb") as buffer:
            # Copie le contenu du fichier téléchargé (file.file) dans le fichier ouvert localement (buffer), en transférant les données binaires.
            #file:objet file
            shutil.copyfileobj(file.file, buffer)
        # Construction de l'URL publique
        image_url = f"http://localhost:8000/static/images/{unique_filename}"
        print(f"✅ Image uploadée : {file_path} → {image_url}")
        return {
            "success": True,
            "url": image_url,
            "filename": unique_filename
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erreur upload image: {e}")
        # status_code=500 indique une erreur interne du serveur
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'upload: {str(e)}")

# ========================================
# ENDPOINTS ADMIN POUR LA GESTION DES VÉHICULES
# ========================================
@app.post("/admin/vehicles")
def add_vehicle(
    vehicle_data: dict,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """
    Ajoute un nouveau véhicule (admin seulement).
    """
    try:
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
            isAvailable=vehicle_data.get('isAvailable', True),
            isNew=vehicle_data.get('isNew', False),
            isBestChoice=vehicle_data.get('isBestChoice', False),
            rating=vehicle_data.get('rating', 0.0),
            popularity=vehicle_data.get('popularity', 0),
            luggage=vehicle_data.get('luggage', 0),
            airConditioning=vehicle_data.get('airConditioning', True),
            bluetooth=vehicle_data.get('bluetooth', True),
        )
        db.add(new_vehicle)
        db.commit()
        db.refresh(new_vehicle)
        return {
            "success": True,
            "message": "Véhicule ajouté avec succès",
            "vehicle_id": new_vehicle.id
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
    """
    Supprime un véhicule (admin seulement) .
    """
    try:
        vehicle = db.query(vehicles).filter(vehicles.id == vehicle_id).first()
        if not vehicle:
            raise HTTPException(status_code=404, detail="Véhicule non trouvé")
        # Vérifie s'il y a des réservations actives sur ce véhicule
        active_bookings = db.query(Booking).filter(
            Booking.car_id == vehicle_id,
            Booking.status.in_(["En attente", "Confirmée"])
        ).count()
        if active_bookings > 0:
            raise HTTPException(
                status_code=400,
                detail=f"Impossible de supprimer : {active_bookings} réservation(s) active(s)"
            )
        # Supprime les favoris liés à ce véhicule
        db.query(Favorite).filter(Favorite.car_id == vehicle_id).delete()
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
    """
    Met à jour les informations d'un véhicule (admin seulement).
    """
    try:
        vehicle = db.query(vehicles).filter(vehicles.id == vehicle_id).first()
        if not vehicle:
            raise HTTPException(status_code=404, detail="Véhicule non trouvé")
        # Mise à jour conditionnelle de chaque champ si présent dans vehicle_data
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
        db.commit()
        db.refresh(vehicle)
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
    """
    Crée une nouvelle conversation pour l'utilisateur courant.
    """
    try:
        new_conversation = Conversation(
            user_id=current_user.id,
            title=conversation_data.title
        )
        db.add(new_conversation)
        db.commit()
        db.refresh(new_conversation)
        return new_conversation
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la création de la conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@app.get("/conversations/", response_model=List[ConversationListResponse])
def get_user_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    # include_inactive est un paramètre booléen qui indique s’il faut inclure ou non les éléments inactifs
    include_inactive: bool = False
):
    """
    Récupère la liste des conversations de l'utilisateur courant.
    """
    try:
        query = db.query(Conversation).filter(Conversation.user_id == current_user.id)
        if not include_inactive:
            query = query.filter(Conversation.is_active == True)
        conversations = query.order_by(Conversation.updated_at.desc()).all()
        result = []
        for conv in conversations:
            message_count = len(conv.messages)
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

@app.post("/conversations/{conversation_id}/messages", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def add_message(
    conversation_id: int,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Ajoute un message dans une conversation (côté utilisateur).
    """
    try:
        conversation = db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        if not conversation:
            raise HTTPException(
                status_code=404,
                detail="Conversation non trouvée ou vous n'avez pas accès à cette conversation"
            )
        new_message = Message(
            conversation_id=conversation_id,
            content=message_data.content,
            is_user=message_data.is_user
        )
        db.add(new_message)
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

# ========================================
# FONCTION DE GÉNÉRATION DE RÉPONSE POUR L'ASSISTANT 
# ========================================
def generate_assistant_response(user_message: str, current_user: User, db: Session) -> str:
    """
    Génère une réponse intelligente de l'assistant en fonction du message utilisateur.
    Utilise des règles et des données contextuelles.
    """
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
    
    # --- 1. COMMENT RÉSERVER ? ---
    if user_message_lower == "comment réserver ?" or ("réserver" in user_message_lower and "comment" in user_message_lower):
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
    
    # --- 2. TARIFS / PRIX (suggestion "Quels sont les tarifs ?") ---
    # Détecte les mots "tarifs", "prix", "combien", "coût", "tarif"
    elif (user_message_lower == "quels sont les tarifs ?" or 
          any(word in user_message_lower for word in ['tarifs', 'tarif', 'prix', 'combien', 'coût'])):
       # Crée un dictionnaire vide pour regrouper les voitures par catégorie
        categories = {}
        # Parcourt chaque voiture dans la liste all_cars
        for car in all_cars:
            cat = car.category
             # Si la catégorie n’existe pas encore dans le dictionnaire
            if cat not in categories:
                        # On crée une nouvelle liste pour cette catégorie
                categories[cat] = []
                  # Ajoute le prix de la voiture (converti en float) dans la liste de sa catégorie
            categories[cat].append(float(car.price))
        
        price_info = "💵 **Tarifs par catégorie (par jour) :**\n\n"
        for cat, prices in categories.items():
            if prices:
                avg = sum(prices) / len(prices)
                price_info += f"• **{cat}** : {avg:.0f} - {max(prices):.0f} TND\n"
        
        price_info += "\n💡 **Informations supplémentaires :**\n"
        price_info += "• Options supplémentaires :\n"
        price_info += "  - Chauffeur : +50 TND/jour\n"
        price_info += "  - GPS : +5 TND/jour\n"
        price_info += "  - Siège enfant : +3 TND/jour\n"
        price_info += "\n🔍 Pour connaître le prix exact d'un véhicule, consultez sa fiche détaillée."
        
        return price_info
    
    # --- 3. FAVORIS (suggestion "Ajouter aux favoris") ---
    # Détecte "favoris", "favori", "ajouter aux favoris", "mes favoris"
    elif any(word in user_message_lower for word in ['favoris', 'favori']):
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
                #-3 car on a déja affiche les noms des 3
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
    
    # --- 4. TYPES DE VÉHICULES (suggestion "Types de véhicules") ---
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
        
        response = "🚗 **Nos catégories de véhicules :**\n\n"
        # Parcourt chaque catégorie et son nombre d’éléments dans le dictionnaire
        for cat, count in category_counts.items():
            # Récupère un exemple associé à la catégorie (ou une chaîne vide si la catégorie n’existe pas)
            example = category_examples.get(cat, "")
            response += f"• **{cat}** ({count} modèles)\n"
            response += f"  *Exemple : {example}*\n"
            response += f"  *Idéal pour : "
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
        
        response += "\n🔍 **Comment choisir ?**\n"
        response += "• Pour la ville : Économique ou Citadine\n"
        response += "• Pour la famille : Familiale ou SUV\n"
        response += "• Pour le confort : Compacte\n"
        response += "• Pour les voyages : SUV\n"
        return response
    
    # --- 5. CONTACTER LE SUPPORT (suggestion "Contacter le support") ---
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
    
    # --- 6. VÉHICULES DISPONIBLES (suggestion "Véhicules disponibles") ---
    elif user_message_lower == "véhicules disponibles" or "disponibles" in user_message_lower:
        # Récupère quelques véhicules disponibles
        available_cars_list = db.query(vehicles).filter(
            vehicles.isAvailable == True
        ).limit(5).all()
        # On compte ici le nombre total de véhicules disponibles (sans la limite de 5).
        available_cars = db.query(vehicles).filter(vehicles.isAvailable == True).count()

        response = f"✅ **Véhicules disponibles :**\n\n"
        response += f"Nous avons actuellement **{available_cars} véhicules** disponibles à la location.\n\n"
        if available_cars_list:
            response += "**Quelques modèles disponibles :**\n"
            for car in available_cars_list:
                #f"..:Permet d’insérer des variables dans une chaîne
                # Convertit le prix en float et l'affiche sans décimales (arrondi à l'entier le plus proche)
                response += f"• **{car.name}** ({car.category}) - {float(car.price):.0f} TND/jour\n"
            response += f"\n💡 **Conseil :** {available_cars} choix disponibles. Réservez vite pour garantir votre véhicule préféré !\n"
        else:
            response += "Aucun véhicule disponible pour le moment.\n"
        
        response += "\n**Filtres disponibles :**\n"
        response += "• Par prix (0 - 500 TND)\n"
        response += "• Par catégorie (Économique, SUV...)\n"
        response += "• Par disponibilité\n"
        response += "• Par nombre de places\n"
        response += "\n🔍 **Comment voir tous les véhicules ?**\n"
        response += "Allez dans 'Nos voitures' et utilisez les filtres pour trouver le véhicule parfait !"
        return response
    
    # --- 7. MODIFIER LE PROFIL (suggestion "Modifier mon profil") ---
    # Détecte "profil", "mon profil", ou des phrases avec "modifier" + "profil/compte"
    elif (user_message_lower == "modifier mon profil" or
          user_message_lower == "profil" or
          user_message_lower == "mon profil" or
          (any(word in user_message_lower for word in ['profil', 'mon compte']) and
           any(word in user_message_lower for word in ['modifier', 'changer']))):
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
Vos données sont cryptées et protégées.

💡 **Besoin d'aide ?** Contactez le support si vous rencontrez des difficultés."""
    
    # --- 8. RÉPONSE GÉNÉRIQUE SUR LES VÉHICULES (si "véhicule(s)" ou "voiture(s)" sans être pris par les cas spécifiques) ---
    elif any(word in user_message_lower for word in ['véhicule', 'véhicules', 'voiture', 'voitures']):
        return """🚗 **Notre gamme de véhicules :**

Nous proposons une large sélection de véhicules adaptés à tous vos besoins :

• **Économique** – Idéal pour petits budgets et déplacements urbains.
• **Citadine** – Confortable et maniable en ville.
• **Familiale** – Espace et confort pour les voyages en famille.
• **SUV** – Polyvalent, parfait pour l'aventure et le tout-terrain.
• **Compacte** – Un bon compromis entre taille et confort.

🔍 **Comment explorer notre catalogue ?**
Rendez-vous dans l'onglet **"Nos voitures"** pour voir tous les modèles disponibles. Vous pouvez filtrer par catégorie, prix, nombre de places, etc."""

    
    # ========================================
    # RÉPONSES GÉNÉRALES BASÉES SUR LES MOTS-CLÉS (salutations, réservations, annulations, remerciements)
    # ========================================
    
    # Salutations
    elif any(word in user_message_lower for word in ['bonjour', 'salut', 'hello', 'hi', 'coucou']):
        return f"Bonjour {current_user.username} ! 👋 Je suis votre assistant CarRental. Comment puis-je vous aider aujourd'hui ?"
    
    # Réservations
    elif any(word in user_message_lower for word in ['réservation', 'réserver', 'louer']):
        if user_bookings:
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
        default_responses = [
            #.format() sert à insérer des variables dans une chaîne
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
    """
    Endpoint pour envoyer un message à l'assistant et recevoir une réponse automatique.
    """
    try:
        # Vérifie que la conversation appartient bien à l'utilisateur
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
            is_user=False
        )
        db.add(assistant_msg)
        conversation.updated_at = datetime.now()
        db.commit()
        db.refresh(user_msg)
        db.refresh(assistant_msg)
        return {
            "success": True,
            "reply": bot_reply,
            "user_message_id": user_msg.id,
            "assistant_message_id": assistant_msg.id,
            "conversation_id": data.conversation_id
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de l'interaction avec l'assistant: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")