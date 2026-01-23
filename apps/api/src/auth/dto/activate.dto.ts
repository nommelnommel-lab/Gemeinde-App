import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class ActivateDto {
  @IsString()
  @IsNotEmpty()
  activationCode!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;

  @IsString()
  @IsNotEmpty()
  postalCode!: string;

  @IsString()
  @IsNotEmpty()
  houseNumber!: string;
}
