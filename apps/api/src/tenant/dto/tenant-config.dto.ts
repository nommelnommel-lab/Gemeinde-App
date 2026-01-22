import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { TENANT_DAYS, TenantDay } from '../tenant.types';

const PHONE_REGEX = /^[+\d()\s-]{6,30}$/;
const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;

export class OpeningHoursDto {
  @IsIn(TENANT_DAYS)
  day: TenantDay;

  @IsOptional()
  @IsBoolean()
  closed?: boolean;

  @ValidateIf((entry) => !entry.closed)
  @IsString()
  @Matches(TIME_REGEX, { message: 'opens muss im Format HH:mm sein' })
  opens?: string;

  @ValidateIf((entry) => !entry.closed)
  @IsString()
  @Matches(TIME_REGEX, { message: 'closes muss im Format HH:mm sein' })
  closes?: string;

  @IsOptional()
  @IsString()
  note?: string;
}

export class EmergencyNumberDto {
  @IsString()
  @IsNotEmpty()
  label: string;

  @IsString()
  @Matches(PHONE_REGEX, {
    message: 'phone muss eine gültige Telefonnummer sein',
  })
  phone: string;
}

export class TenantConfigDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Matches(PHONE_REGEX, {
    message: 'contactPhone muss eine gültige Telefonnummer sein',
  })
  contactPhone: string;

  @IsEmail()
  contactEmail: string;

  @IsUrl({ require_protocol: true })
  websiteUrl: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OpeningHoursDto)
  openingHours: OpeningHoursDto[];

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => EmergencyNumberDto)
  emergencyNumbers: EmergencyNumberDto[];
}
