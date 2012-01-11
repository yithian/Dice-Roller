#!/usr/bin/env ruby
begin
	require 'gtk2'
	$GUI_TYPE = 'gtk'
rescue LoadError
	require 'osx/cocoa'
	include OSX
	$GUI_TYPE = 'cocoa'
end


###  A class representing a single die.  Rolling this die passes output to a buffer (string)
class Die
	def initialize(faces = 6, outbuffer = '')
		@faces = faces
		@outbuffer = outbuffer
	end
	def roll()
		tmp = rand(@faces) + 1
		@outbuffer = @outbuffer << "#{@faces}-sided die => #{tmp}\n"
		tmp
	end

	attr_accessor :faces, :outbuffer
end

### A class representing a bunch of dice (many objects of class Die).  Rolling this die pool passes output to a buffer indicated by the die.
class DicePool
	def initialize(four = 0, six = 0, eight = 0, ten = 0, twelve = 0, twenty = 0, percent = 0)
		@four = four
		@six = six
		@eight = eight
		@ten = ten
		@twelve = twelve
		@twenty = twenty
		@percent = percent
	end
	def roll_pool(success_value = 8, sum_num = false, number_successes = true, one_cancels = false, roll_again = 10, outbuffer = '')
		buffer = outbuffer
		sum_value = 0
		successes = 0
		ones = 0
		rerolls = 0
		rote_rerolls = 0
		roll_again = roll_again.to_i
		rote = false
		
		if roll_again == 0
			roll_again = 10
			rote = true
		end
		
		four_side = Die.new(4, buffer)
		six_side = Die.new(6, buffer)
		eight_side = Die.new(8, buffer)
		ten_side = Die.new(10, buffer)
		twelve_side = Die.new(12, buffer)
		twenty_side = Die.new(20, buffer)
		percentile = Die.new(100, buffer)

		@four.times do
			sum_value += four_side.roll()
		end
		@six.times do
			sum_value += six_side.roll()
		end
		@eight.times do
			sum_value += eight_side.roll()
		end
		@ten.times do
			is_rote = rote
			
			while tmp = ten_side.roll()
				sum_value += tmp
				successes += 1 if tmp >= success_value
				rerolls += 1 if tmp >= roll_again
				if tmp <= 1
					ones += 1
					successes -= 1 if one_cancels
				end

				break unless number_successes
				if tmp >= roll_again
					next
				elsif is_rote and ( tmp < roll_again )
					is_rote = false
					rote_rerolls += 1
					next
				else
					break
				end
			end
		end
		@twelve.times do
			sum_value += twelve_side.roll()
		end
		@twenty.times do
			sum_value += twenty_side.roll()
		end
		@percent.times do
			sum_value += percentile.roll()
		end

		buffer = buffer << "Ones Rolled: #{ones}\n" if one_cancels and number_successes 
		buffer = buffer << "Re-rolls: #{rerolls}\n" unless ((@four + @six + @eight + @twelve + @twenty + @percent) != 0) or sum_num
		buffer = buffer << "Rote Re-rolls: #{rote_rerolls}\n" if rote and ((@four + @six + @eight + @twelve + @twenty + @percent) == 0) and ! sum_num
		buffer = buffer << "Successes: #{successes}\n" if number_successes
		buffer = buffer << "Sum Value: #{sum_value}\n" if sum_num

		buffer
	end

	attr_accessor :four, :six, :eight, :ten, :twelve, :twenty, :percent
end

case $GUI_TYPE
when 'gtk'
	class DiceInterface
		def initialize()
			window = Gtk::Window.new
			window.title = 'dice-roller'

			### Gtk objects for interface
			# main layout
			layout = Gtk::Table.new(9, 5)
			window.add(layout)
			# entry fields for die types
			edit_d4 = Gtk::Entry.new
			edit_d4.xalign = 1
			edit_d4.width_chars = 2
			edit_d4.activates_default = true
			edit_d6 = Gtk::Entry.new
			edit_d6.xalign = 1
			edit_d6.width_chars = 2
			edit_d6.activates_default = true
			edit_d8 = Gtk::Entry.new
			edit_d8.xalign = 1
			edit_d8.width_chars = 2
			edit_d8.activates_default = true
			edit_d10 = Gtk::Entry.new
			edit_d10.xalign = 1
			edit_d10.width_chars = 2
			edit_d10.activates_default = true
			edit_d12 = Gtk::Entry.new
			edit_d12.xalign = 1
			edit_d12.width_chars = 2
			edit_d12.activates_default = true
			edit_d20 = Gtk::Entry.new
			edit_d20.xalign = 1
			edit_d20.width_chars = 2
			edit_d20.activates_default = true
			edit_d100 = Gtk::Entry.new
			edit_d100.xalign = 1
			edit_d100.width_chars = 2
			edit_d100.activates_default = true
			# labels for dice entry fields
			label_d4 = Gtk::Label.new('d_4', true)
			label_d4.xalign = 0
			label_d4.mnemonic_widget = edit_d4
			label_d6 = Gtk::Label.new('d_6', true)
			label_d6.xalign = 0
			label_d6.mnemonic_widget = edit_d6
			label_d8 = Gtk::Label.new('d_8', true)
			label_d8.xalign = 0
			label_d8.mnemonic_widget = edit_d8
			label_d10 = Gtk::Label.new('_d10', true)
			label_d10.xalign = 0
			label_d10.mnemonic_widget = edit_d10
			label_d12 = Gtk::Label.new('d_12', true)
			label_d12.xalign = 0
			label_d12.mnemonic_widget = edit_d12
			label_d20 = Gtk::Label.new('d_20', true)
			label_d20.xalign = 0
			label_d20.mnemonic_widget = edit_d20
			label_d100 = Gtk::Label.new('d10_0', true)
			label_d100.xalign = 0
			label_d100.mnemonic_widget = edit_d100
			# options
			@combo_again = Gtk::ComboBox.new
				@combo_again.append_text('')
				@combo_again.append_text('8 again')
				@combo_again.append_text('9 again')
				@combo_again.append_text('10 again')
			@combo_again.active = 3
			@combo_again.focus_on_click = false
			@check_negate = Gtk::CheckButton.new('1 _negates')
			@radio_successes = Gtk::RadioButton.new('_Total Successes')
			@radio_sum_value = Gtk::RadioButton.new(@radio_successes, '_Sum value')
			# buffer for output and output text area
			@buffer_out = Gtk::TextBuffer.new
			edit_out = Gtk::TextView.new(@buffer_out)
			edit_out.editable = false
			edit_out.cursor_visible = false
			scrollwin_out = Gtk::ScrolledWindow.new
			scrollwin_out.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC)
			scrollwin_out.add_with_viewport(edit_out)
			# roll button
			button_roll = Gtk::Button.new('Roll!')
			button_roll.set_flags( Gtk::Widget::CAN_DEFAULT )
			
			### Put together the interface
			# Output window
			layout.attach(scrollwin_out, 0, 2, 0, 7)
			# Dice labels/inputs
			layout.attach(edit_d4, 2, 3, 0, 1)
			layout.attach(label_d4, 3, 4, 0, 1)
			layout.attach(edit_d6, 2, 3, 1, 2)
			layout.attach(label_d6, 3, 4, 1, 2)
			layout.attach(edit_d8, 2, 3, 2, 3)
			layout.attach(label_d8, 3, 4, 2, 3)
			layout.attach(edit_d10, 2, 3, 3, 4)
			layout.attach(label_d10, 3, 4, 3, 4)
			layout.attach(edit_d12, 2, 3, 4, 5)
			layout.attach(label_d12, 3, 4, 4, 5)
			layout.attach(edit_d20, 2, 3, 5, 6)
			layout.attach(label_d20, 3, 4, 5, 6)
			layout.attach(edit_d100, 2, 3, 6, 7)
			layout.attach(label_d100, 3, 4, 6, 7)
			# Option fields
			layout.attach(@combo_again, 0, 1, 7, 8)
			layout.attach(@check_negate, 1, 2, 7, 8)
			layout.attach(@radio_successes, 0, 1, 8, 9)
			layout.attach(@radio_sum_value, 1, 2, 8, 9)
			# Roll button
			layout.attach(button_roll, 2, 4, 7, 9)
			button_roll.grab_default
			# Set focus order
			layout.focus_chain = edit_d10, edit_d12, edit_d20, edit_d100, edit_d4, edit_d6, edit_d8

			window.show_all
			window.signal_connect('delete_event') { Gtk.main_quit }
			# Roll the dice!
			button_roll.signal_connect('clicked') do
				@buffer_out.delete(@buffer_out.start_iter, @buffer_out.end_iter)

				dice = DicePool.new(edit_d4.text.to_i, edit_d6.text.to_i, edit_d8.text.to_i, edit_d10.text.to_i, edit_d12.text.to_i, edit_d20.text.to_i, edit_d100.text.to_i)
				if @combo_again.active_text.eql?('')
					reroll = 11
				else
					reroll = @combo_again.active_text.to_i
				end
				buffer = dice.roll_pool(8, @radio_sum_value.active?, @radio_successes.active?, @check_negate.active?, reroll)

				@buffer_out.insert(@buffer_out.start_iter, buffer)
			end
		end
	end

	DiceInterface.new()		# If running gtk, this creates the window
	Gtk.main				# and this sets the spinning loop
when 'cocoa'
	class DiceInterface < NSWindowController
		def initialize
			@@reroll = 10
			@@negate = false
			@@success = true
			@@total = false
			@@d4 = 0
			@@d6 = 0
			@@d8 = 0
			@@d10 = 0
			@@d12 = 0
			@@d20 = 0
			@@d100 = 0
			@@buffer = ''
		end
		
		ib_outlet :outfield
		ib_outlet :main_window
		
		def awakeFromNib()
			@main_window.setDelegate_(self)
		end
		
		def windowWillClose_(note)
			NSApp.terminate(self)
		end
				
		def negate(sender)
			if sender.state == 1
				@@negate = true
			else
				@@negate = false
			end
		end
		ib_action :negate
		
		def succsess_mode(sender)
			@@success = true
			@@total = false
		end
		ib_action :succsess_mode
		
		def total_mode(sender)
			@@success = false
			@@total = true
		end
		ib_action :total_mode
		
		def d4_value(sender)
			@@d4 = sender.stringValue().intValue()
		end
		ib_action :d4_value
		
		def d6_value(sender)
			@@d6 = sender.stringValue().intValue()
		end
		ib_action :d6_value
		
		def d8_value(sender)
			@@d8 = sender.stringValue().intValue()
		end
		ib_action :d8_value
		
		def d10_value(sender)
			@@d10 = sender.stringValue().intValue()
		end
		ib_action :d10_value
		
		def d12_value(sender)
			@@d12 = sender.stringValue().intValue()
		end
		ib_action :d12_value
		
		def d20_value(sender)
			@@d20 = sender.stringValue().intValue()
		end
		ib_action :d20_value
		
		def d100_value(sender)
			@@d100 = sender.stringValue().intValue()
		end
		ib_action :d100_value
		
		def reroll_value(sender)
			@@reroll = sender.titleOfSelectedItem()
		end
		ib_action :reroll_value
		
		def roll_dice(sender)
			@@buffer = ''
			dice = DicePool.new(@@d4, @@d6, @@d8, @@d10, @@d12, @@d20, @@d100)
			@@buffer = dice.roll_pool(8, @@total, @@success, @@negate, @@reroll)
			@outfield.setString(@@buffer)
			@outfield.scrollRangeToVisible_([@outfield.string().length, @outfield.string.length])
		end
		ib_action :roll_dice
	end
end