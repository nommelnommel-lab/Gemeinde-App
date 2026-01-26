import { IsString, MinLength } from 'class-validator';

export class TouristRedeemDto {
  @IsString()
  @MinLength(6)
  code!: string;

  @IsString()
  @MinLength(3)
  deviceId!: string;
}
