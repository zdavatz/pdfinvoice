#!/usr/bin/env ruby
# Invoice -- pdfinvoice -- 25.07.2005 -- hwyss@ywesee.com

begin
	require 'rubygems'
rescue LoadError
	warn "could not load 'rubygems'"
end
require 'pdf/writer'
require 'pdf/simpletable'

module PdfInvoice
	class Invoice
		attr_accessor :invoice_number, :debitor_address, :items
		def initialize(config)
			@config = config
			@date = Date.today
			@items = []
		end
		def to_pdf
			pdf = PDF::Writer.new
			pdf.margins_pt(pdf.mm2pts(15), pdf.mm2pts(25), 
				pdf.mm2pts(15), pdf.mm2pts(15))
			pdf.select_font(@config.font)
			pdf_header(pdf)
			pdf_items(pdf)
			pdf_footer(pdf)
			pdf.render
		end
		private
		def currency_format(amount, fmt='currency')
			sprintf(@config.formats[fmt], amount)
		end
		def pdf_footer(pdf)
			if(txt = @config.texts['thanks'])
				pdf.move_pointer(pdf.font_height)
				pdf.text(txt, @config.text_options)
			end
		end
		def pdf_header(pdf)
			if(path = @config.logo_path)
				args = {:pad => 0}
				if(url = @config.logo_link)
					args.store(:link, url)
				end
				pdf.image(path, args)
			end
			pdf.start_columns(2)
			pdf.text(sprintf(@config.formats['invoice_number'], 
				@invoice_number), @config.text_options) 
			pdf.start_new_page
			pdf_lines(pdf, @config.creditor_address)
			pdf.stop_columns
			pdf.start_columns(2)
			pdf_lines(pdf, @debitor_address)
			pdf.start_new_page
			pdf.text(@config.creditor_email, @config.text_options)
			pdf_lines(pdf, @config.creditor_bank)
			pdf.stop_columns
			pdf.move_pointer(pdf.font_height)
			pdf.start_columns(2)
			pdf.text(@config.due_days, @config.text_options)
			pdf.start_new_page
			pdf.text(@date.strftime(@config.formats['date']), 
				@config.text_options)
			pdf.stop_columns
		end
		def pdf_items(pdf)
			sstyle = PDF::Writer::StrokeStyle::DEFAULT.dup
			sstyle.width = 0.5
			sstyle.dash = { :pattern => [1] }
			pdf.start_columns(1)
			pdf.move_pointer(pdf.font_height)
			total = 0.0
			left = 0
			width = 0
			col_width = 0
			row_gap = 4
			pdf.select_font(@config.font_b)
			['Zwischensumme', 'MwSt 7.5%', 'Fälliger Betrag'].each { |title|
				cw = pdf.text_width(title) * PDF::SimpleTable::WIDTH_FACTOR
				col_width = [col_width, cw].max
			}
			pdf.select_font(@config.font)
			PDF::SimpleTable.new { |table|
				columns = ['date', 'description', 'unit', 'quantity', 'price', 
					'item_total']
				headings = columns.collect { |col| @config.texts[col] }
				table.column_order = columns
				columns.each_with_index { |col, idx|
					table.columns[col] = PDF::SimpleTable::Column.new('date') { 
						|column|
						column.heading = PDF::SimpleTable::Column::Heading.new(col)
						column.heading.title = headings.at(idx)
						if(['quantity', 'price', 'item_total'].include?(col))
							column.justification = :right
							column.heading.justification = :right
						end
					}
				}
				table.data = @items.collect { |line|
					item_total = line.at(3).to_f * line.at(4).to_f
					total += item_total
					date = line.at(0).strftime(@config.formats['date'])
					cw = pdf.text_width(date) * PDF::SimpleTable::WIDTH_FACTOR
					col_width = [col_width, cw].max
					{
						'date'				=> date,
						'description'	=> line.at(1),
						'unit'				=> line.at(2),
						'quantity'		=> sprintf('%1.2f', line.at(3)),
						'price'				=> currency_format(line.at(4)),
						'item_total'	=> currency_format(item_total),
					}
				}
				col_width += 2 * table.column_gap
				table.columns['date'].width = col_width
				table.position = left = pdf.left_margin + table.column_gap
				table.orientation = :right
				table.width = width = pdf.margin_width - 2 * table.column_gap
				cl = Color::RGB.new(*@config.colors['items'])
				table.shade_color2 = table.shade_color = cl
				table.shade_rows = :striped
				table.show_lines = :all
				table.inner_line_style = sstyle
				table.outer_line_style = sstyle
				table.row_gap = row_gap
				table.bold_headings = true
				table.heading_font_size = 10
				table.render_on(pdf)
			}
			pdf.select_font(@config.font_b)
			PDF::SimpleTable.new { |table|
				table.column_order = ['date', 'total']
				table.data = [
					{	'date' => @config.texts['subtotal'], 
						'total' => currency_format(total, 'total')},
					{	'date' => @config.texts['tax'], 
						'total' => currency_format(total * @config.tax.to_f, 
							'total') },
					{	'date' => @config.texts['total'], 
						'total' => currency_format(total * (1 + @config.tax.to_f),
							'total') },
				]
				table.show_headings = false
				table.position = left
				table.orientation = :right
				table.width = width 
				table.columns['date'] = PDF::SimpleTable::Column.new('date') { 
					|column|
					column.width = col_width
				}
				table.columns['total'] = PDF::SimpleTable::Column.new('date') {
					|column|
					column.justification = :right
				}
				cl = Color::RGB.new(*@config.colors['total'])
				table.shade_color2 = table.shade_color = cl
				table.shade_rows = :striped
				table.show_lines = :all
				table.inner_line_style = sstyle
				table.outer_line_style = sstyle
				table.row_gap = row_gap
				table.render_on(pdf)
			}
			pdf.select_font(@config.font)
		end
		def pdf_lines(pdf, lines)
			if(lines)
				lines.each { |line|
					pdf.text(line.strip, @config.text_options) 
				}
			end
		end
	end
end
