import bcrypt from 'bcryptjs';

export class BcryptPasswordHasher {
  hash(password: string) {
    return bcrypt.hash(password, 12);
  }

  verify(password: string, hash: string) {
    return bcrypt.compare(password, hash);
  }
}
