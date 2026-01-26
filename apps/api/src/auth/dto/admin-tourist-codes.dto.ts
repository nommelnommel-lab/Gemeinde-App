import { Type } from 'class-transformer';
import { IsIn, IsInt, Max, Min } from 'class-validator';

export class TouristCodeGenerateDto {
  @Type(() => Number)
  @IsInt()
  @IsIn([7, 14, 30])
  durationDays!: 7 | 14 | 30;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(1000)
  amount!: number;
}
