from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import CurrentUser
from app.auth.repository import AuthRepository
from app.auth.schemas import (
    CurrentUserResponse,
    LoginRequest,
    LoginResponse,
    LoginUserResponse,
)
from app.auth.service import AuthService
from app.core.database import get_db

router = APIRouter(
    prefix="/api/v1/auth",
    tags=["Autenticación"],
)


@router.post(
    "/login",
    response_model=LoginResponse,
    status_code=status.HTTP_200_OK,
    summary="Autenticar operador",
)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
) -> LoginResponse:
    repository = AuthRepository(db)
    service = AuthService(repository)

    result = service.login(
        username=request.username,
        password=request.password,
    )

    return LoginResponse(
        access_token=result.access_token,
        token_type="bearer",
        expires_in=result.expires_in,
        user=LoginUserResponse(
            id=result.user.user_id,
            username=result.user.username,
            display_name=result.user.display_name,
        ),
    )


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    summary="Obtener usuario autenticado",
)
def get_me(
    current_user: CurrentUser,
) -> CurrentUserResponse:
    return CurrentUserResponse(
        id=current_user.user_id,
        username=current_user.username,
        display_name=current_user.display_name,
    )
