const Reservation = require('../models/Reservation');

describe('Reservation model', () => {
  describe('serviceOptions', () => {
    it('accepts every option offered in the app', () => {
      const reservation = new Reservation({ serviceOptions: Reservation.SERVICE_OPTIONS });
      const error = reservation.validateSync();
      const optionErrors = Object.keys(error?.errors || {}).filter((k) => k.startsWith('serviceOptions'));
      expect(Reservation.SERVICE_OPTIONS).toHaveLength(8);
      expect(optionErrors).toEqual([]);
    });

    it('still rejects an unknown option', () => {
      const error = new Reservation({ serviceOptions: ['carWash'] }).validateSync();
      expect(error.errors['serviceOptions.0']).toBeDefined();
    });
  });

  describe('computeRequiredEquipment', () => {
    it('always requires a shovel and a brush', () => {
      expect(Reservation.computeRequiredEquipment({})).toEqual(['shovel', 'brush']);
    });

    it('adds the equipment of each option without duplicates', () => {
      const required = Reservation.computeRequiredEquipment({
        serviceOptions: ['windowScraping', 'doorDeicing', 'roofClearing', 'exhaustCheck'],
      });
      expect(required).toEqual(['shovel', 'brush', 'ice_scraper', 'deicer_spray', 'roof_broom']);
    });

    it('only produces equipment the model accepts, for every option', () => {
      const reservation = new Reservation({
        serviceOptions: Reservation.SERVICE_OPTIONS,
        snowDepthCm: 30,
      });
      reservation.requiredEquipment = Reservation.computeRequiredEquipment(reservation);
      const error = reservation.validateSync();
      const equipmentErrors = Object.keys(error?.errors || {}).filter((k) => k.startsWith('requiredEquipment'));
      expect(equipmentErrors).toEqual([]);
    });

    it('requires a snow blower above 15 cm only', () => {
      expect(Reservation.computeRequiredEquipment({ snowDepthCm: 15 })).not.toContain('snow_blower');
      expect(Reservation.computeRequiredEquipment({ snowDepthCm: 25 })).toContain('snow_blower');
    });
  });
});
