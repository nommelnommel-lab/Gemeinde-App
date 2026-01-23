const DASH_VARIANTS = /[\u2010\u2011\u2012\u2013\u2014\u2212\u00AD]/g;

export const normalizeActivationCode = (input: string) => {
  return input
    .trim()
    .toUpperCase()
    .replace(DASH_VARIANTS, '-')
    .replace(/\s+/g, '')
    .replace(/[^A-Z0-9-]/g, '')
    .replace(/-+/g, '-');
};
