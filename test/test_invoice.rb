#!/usr/bin/env ruby
# TestInvoice -- pdfinvoice -- 25.07.2005 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'pdfinvoice/invoice'
require 'rclconf'

module PdfInvoice
  class Invoice
    public :number_format
  end
	class TestInvoice < Test::Unit::TestCase
		def setup
			logo_path = File.expand_path('data/logo.png', 
				File.dirname(__FILE__))
			address = <<-EOS
ywesee GmbH
Winterthurerstrasse 52
8006 Z�rich
			EOS
			bank = <<-EOS
MwSt-Nummer: 612 860
UBS-R�merhof Z�rich
Kontonummer: 808888.01M, Clearingnummer: 251
IBAN: CH450025125180888801M
			EOS
			defaults = {
				'colors'						=> {
					'items'						=> [0xF8, 0xF8, 0xF8],	
					'total'						=> [0xF0, 0xF0, 0xF0],	
				},
				'creditor_address'	=> address,
				'creditor_email'		=> "zdavatz@ywesee.com",
				'creditor_bank'			=> bank,
				'due_days'					=> 'Bedingungen: zahlbar in 10 Tagen',
				'font'							=> 'Helvetica',
				'font_b'						=> 'Helvetica-Bold',
				'formats'						=> {
					'total'						=> "CHF %1.2f",
					'currency'				=> "CHF %1.2f",
					'date'						=> "%d.%m.%Y",
					'invoice_number'	=> "<b>Rechnung #%06i</b>",
					'quantity'				=> '%1.3f',
				},
				'logo_path'					=> logo_path,
				'logo_link'					=> {
					:type							=> :external,
					:target						=> 'http://www.ywesee.com',
				},
				'tax'								=> 0.076,
				'texts'							=> {
					'date'						=> 'Datum',	
					'description'			=> 'Beschreibung',
					'unit'						=> 'Einheit',
					'quantity'				=> 'Anzahl',
					'price'						=> 'St�ckpreis',
					'item_total'			=> 'Betrag',
					'subtotal'				=> 'Zwischensumme',
					'tax'							=> 'MwSt 7.6%',
					'thanks'					=> 'Thank you for your patronage',
					'total'						=> 'F�lliger Betrag',
				},
				'text_options'			=> {:spacing => 1.25},
			}
			@config = RCLConf::RCLConf.new([], defaults)
			@invoice = Invoice.new(@config)
			@invoice.items = [
				[Date.today, "Invalid Invoice", "No Data", 0, 0],
			]
		end
		def write_testfile(pdf)
			path = File.expand_path('../test.pdf', File.dirname(__FILE__))
			File.open(path, 'w') { |fh| fh.puts pdf }
		end
		def test_to_pdf__no_items
			@invoice = Invoice.new(@config)
			assert_raises(TypeError) { @invoice.to_pdf }
		end
		def test_to_pdf__defaults
			pdf = @invoice.to_pdf
			[
				"(ywesee GmbH)",
				"(Winterthurerstrasse 52)",
				"(8006 Z�rich)",
				"(zdavatz@ywesee.com)",
				"(MwSt-Nummer: 612 860)",
				"(UBS-R�merhof Z�rich)",
				"(Kontonummer: 808888.01M, Clearingnummer: 251)",
				"(IBAN: CH450025125180888801M)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__logo
			pdf = @invoice.to_pdf
			[
				"/ColorSpace /DeviceRGB",
				"/Subtype /Image",
				"/Type /XObject",
				"/URI (http://www.ywesee.com)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__invoice_number
			@invoice.invoice_number = 64
			pdf = @invoice.to_pdf
			line = "(Rechnung #000064)"
			assert_not_nil(pdf.index(line), 
				"could not find #{line} in the generated pdf")
		end
		def test_to_pdf__invoice_number_description
			@invoice.invoice_number = 64
			@invoice.description = 'description'
			pdf = @invoice.to_pdf
			[
				"(Rechnung #000064)",
				"(description)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__debitor_address_1
			@invoice.debitor_address = <<-EOS
Debitor AG
z.H. Herr Ausleih Schlumpf
Pilzstrasse 123
7777 Schlumpfhausen
			EOS
			pdf = @invoice.to_pdf
			[
				"(Debitor AG)",
				"(z.H. Herr Ausleih Schlumpf)",
				"(Pilzstrasse 123)",
				"(7777 Schlumpfhausen)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__debitor_address_2
			@invoice.debitor_address = [
				"Debitor AG",
				"z.H. Herr Ausleih Schlumpf",
				"Pilzstrasse 123",
				"7777 Schlumpfhausen",
			]
			pdf = @invoice.to_pdf
			[
				"(Debitor AG)",
				"(z.H. Herr Ausleih Schlumpf)",
				"(Pilzstrasse 123)",
				"(7777 Schlumpfhausen)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__footer
			pdf = @invoice.to_pdf
			[
				"(Thank you for your patronage)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
		def test_to_pdf__items
			@invoice.items = [
				[Date.new(2005, 7, 25), "Item 1", "Unit", 1, 2500],
				[Date.new(2005, 7, 25), "Item 2", "Unit", 1, 1500],
			]
			pdf = @invoice.to_pdf
			[
				"(Zwischensumme)",
				"(CHF 4000.00)",
				"(MwSt 7.6%)",
				"(CHF 304.00)",
				"(F�lliger Betrag)",
				"(CHF 4304.00)",
			].each { |line|
				assert_not_nil(pdf.index(line), 
					"could not find #{line} in the generated pdf")
			}
		end
    def test_number_format
      assert_equal "155",  @invoice.number_format('155')
      assert_equal "15.5", @invoice.number_format('15.5')
      assert_equal '1.55', @invoice.number_format('1.55')
      assert_equal "1'555", @invoice.number_format('1555')
      assert_equal "155.5", @invoice.number_format('155.5')
      assert_equal '15.55', @invoice.number_format('15.55')
      assert_equal '1.555', @invoice.number_format('1.555')
      assert_equal "15'555",  @invoice.number_format('15555')
      assert_equal "1'555.5", @invoice.number_format('1555.5')
      assert_equal '155.55',  @invoice.number_format('155.55')
      assert_equal '15.555',  @invoice.number_format('15.555')
      assert_equal '1.5555',  @invoice.number_format('1.5555')
      assert_equal "155'555",  @invoice.number_format('155555')
      assert_equal "15'555.5", @invoice.number_format('15555.5')
      assert_equal "1'555.55", @invoice.number_format('1555.55')
      assert_equal "155.555",  @invoice.number_format('155.555')
      assert_equal "15.5555",  @invoice.number_format('15.5555')
      assert_equal "1.55555",  @invoice.number_format('1.55555')
      assert_equal "1'555'555", @invoice.number_format('1555555')
      assert_equal "155'555.5", @invoice.number_format('155555.5')
      assert_equal "15'555.55", @invoice.number_format('15555.55')
      assert_equal "1'555.555", @invoice.number_format('1555.555')
      assert_equal "155.5555",  @invoice.number_format('155.5555')
      assert_equal "15.55555",  @invoice.number_format('15.55555')
      assert_equal "1.555555",  @invoice.number_format('1.555555')
    end
	end
end
