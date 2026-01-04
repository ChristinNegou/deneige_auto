import 'package:flutter_test/flutter_test.dart';
import 'package:deneige_auto/core/services/tax_service.dart';

void main() {
  late TaxService taxService;

  setUp(() {
    taxService = TaxService();
  });

  group('TaxService', () {
    group('getTaxInfo', () {
      test('should return Quebec tax info for QC', () {
        final taxInfo = taxService.getTaxInfo('QC');

        expect(taxInfo.code, 'QC');
        expect(taxInfo.name, 'Québec');
        expect(taxInfo.gstRate, 0.05);
        expect(taxInfo.pstRate, 0.09975);
        expect(taxInfo.isHST, false);
        expect(taxInfo.federalTaxName, 'TPS');
        expect(taxInfo.provincialTaxName, 'TVQ');
      });

      test('should return Ontario tax info for ON', () {
        final taxInfo = taxService.getTaxInfo('ON');

        expect(taxInfo.code, 'ON');
        expect(taxInfo.name, 'Ontario');
        expect(taxInfo.isHST, true);
        expect(taxInfo.hstRate, 0.13);
      });

      test('should return default (Quebec) for unknown province', () {
        final taxInfo = taxService.getTaxInfo('XX');

        expect(taxInfo.code, 'QC');
      });

      test('should handle lowercase province codes', () {
        final taxInfo = taxService.getTaxInfo('qc');

        expect(taxInfo.code, 'QC');
      });
    });

    group('detectProvinceFromAddress', () {
      test('should detect Quebec from postal code starting with G', () {
        final province = taxService.detectProvinceFromAddress('123 Rue Main, G1R 2H3');
        expect(province, 'QC');
      });

      test('should detect Quebec from postal code starting with H', () {
        final province = taxService.detectProvinceFromAddress('123 Rue Main, H2X 3P2');
        expect(province, 'QC');
      });

      test('should detect Ontario from postal code starting with M', () {
        final province = taxService.detectProvinceFromAddress('123 Street, M5V 2T6');
        expect(province, 'ON');
      });

      test('should detect British Columbia from postal code starting with V', () {
        final province = taxService.detectProvinceFromAddress('123 Street, V6B 2W2');
        expect(province, 'BC');
      });

      test('should detect Alberta from postal code starting with T', () {
        final province = taxService.detectProvinceFromAddress('123 Street, T2P 3C4');
        expect(province, 'AB');
      });

      test('should detect province from name in address', () {
        final province = taxService.detectProvinceFromAddress('Toronto, Ontario, Canada');
        expect(province, 'ON');
      });

      test('should detect Quebec from French name', () {
        final province = taxService.detectProvinceFromAddress('Montréal, Québec');
        expect(province, 'QC');
      });

      test('should return default for empty address', () {
        final province = taxService.detectProvinceFromAddress('');
        expect(province, 'QC');
      });

      test('should return default for null address', () {
        final province = taxService.detectProvinceFromAddress(null);
        expect(province, 'QC');
      });

      test('should detect from province code in address', () {
        final province = taxService.detectProvinceFromAddress('Vancouver, BC');
        expect(province, 'BC');
      });
    });

    group('calculateTaxes', () {
      test('should calculate Quebec taxes correctly (TPS + TVQ)', () {
        final result = taxService.calculateTaxes(100.0, 'QC');

        expect(result.subtotal, 100.0);
        expect(result.federalTax, 5.0); // 5% TPS
        expect(result.federalTaxRate, 0.05);
        expect(result.federalTaxName, 'TPS');
        expect(result.provincialTax, closeTo(9.975, 0.001)); // 9.975% TVQ
        expect(result.provincialTaxRate, 0.09975);
        expect(result.provincialTaxName, 'TVQ');
        expect(result.total, closeTo(114.975, 0.001));
        expect(result.isHST, false);
        expect(result.provinceCode, 'QC');
        expect(result.provinceName, 'Québec');
      });

      test('should calculate Ontario HST correctly', () {
        final result = taxService.calculateTaxes(100.0, 'ON');

        expect(result.subtotal, 100.0);
        expect(result.federalTax, 13.0); // 13% HST
        expect(result.federalTaxRate, 0.13);
        expect(result.federalTaxName, 'HST');
        expect(result.provincialTax, 0.0);
        expect(result.total, 113.0);
        expect(result.isHST, true);
      });

      test('should calculate Alberta taxes (GST only)', () {
        final result = taxService.calculateTaxes(100.0, 'AB');

        expect(result.subtotal, 100.0);
        expect(result.federalTax, 5.0); // 5% GST
        expect(result.provincialTax, 0.0); // No PST
        expect(result.total, 105.0);
        expect(result.isHST, false);
      });

      test('should calculate BC taxes (GST + PST)', () {
        final result = taxService.calculateTaxes(100.0, 'BC');

        expect(result.subtotal, 100.0);
        expect(result.federalTax, closeTo(5.0, 0.001)); // 5% GST
        expect(result.provincialTax, closeTo(7.0, 0.001)); // 7% PST
        expect(result.total, closeTo(112.0, 0.001));
      });

      test('should calculate taxes for small amounts', () {
        final result = taxService.calculateTaxes(10.0, 'QC');

        expect(result.subtotal, 10.0);
        expect(result.federalTax, 0.5);
        expect(result.provincialTax, closeTo(0.9975, 0.0001));
      });

      test('should calculate taxes for large amounts', () {
        final result = taxService.calculateTaxes(1000.0, 'QC');

        expect(result.subtotal, 1000.0);
        expect(result.federalTax, 50.0);
        expect(result.provincialTax, closeTo(99.75, 0.01));
        expect(result.total, closeTo(1149.75, 0.01));
      });
    });

    group('TaxCalculation getters', () {
      test('totalTaxes should return sum of federal and provincial', () {
        final result = taxService.calculateTaxes(100.0, 'QC');

        expect(result.totalTaxes, closeTo(14.975, 0.001));
      });

      test('federalTaxLabel should format correctly for Quebec', () {
        final result = taxService.calculateTaxes(100.0, 'QC');

        expect(result.federalTaxLabel, contains('TPS'));
        expect(result.federalTaxLabel, contains('5'));
      });

      test('provincialTaxLabel should format correctly for Quebec', () {
        final result = taxService.calculateTaxes(100.0, 'QC');

        expect(result.provincialTaxLabel, contains('TVQ'));
        expect(result.provincialTaxLabel, contains('9.975'));
      });

      test('provincialTaxLabel should be empty for HST provinces', () {
        final result = taxService.calculateTaxes(100.0, 'ON');

        expect(result.provincialTaxLabel, isEmpty);
      });
    });

    group('ProvinceTaxInfo', () {
      test('totalTaxRate should return HST rate for HST provinces', () {
        final taxInfo = taxService.getTaxInfo('ON');

        expect(taxInfo.totalTaxRate, 0.13);
      });

      test('totalTaxRate should return sum for non-HST provinces', () {
        final taxInfo = taxService.getTaxInfo('QC');

        expect(taxInfo.totalTaxRate, closeTo(0.14975, 0.0001));
      });
    });
  });
}
