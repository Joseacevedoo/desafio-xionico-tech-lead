from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(
        min_length=1,
        max_length=100,
        examples=["operador"],
    )
    password: str = Field(
        min_length=1,
        max_length=200,
        examples=["Demo123!"],
    )


class LoginUserResponse(BaseModel):
    id: int
    username: str
    display_name: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: LoginUserResponse


class CurrentUserResponse(BaseModel):
    id: int
    username: str
    display_name: str
