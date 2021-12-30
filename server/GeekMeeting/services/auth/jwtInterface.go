package auth

type JwtTool interface {
	GetKey() []byte
	SetKey(key []byte)
	NewToken(userId int64) (accessToken, refreshToken string, err error)
	ParseToken(tokenStr string) (int64, bool, error)
	RefreshToken(tokenStr, oldToken string) (accessToken, refreshToken string, err error)
}
