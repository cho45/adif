#!rspec
require 'spec_helper'

describe ADIF do
	it 'has a version number' do
		expect(ADIF::VERSION).not_to be nil
	end

	context "ADI" do
		it 'can parse adif from spec' do
			data = ADIF.parse_adi("<call:6>WN4AZY<band:3>20M<mode:4>RTTY<qso_date:8>19960513<time_on:4>1305<eor>").records
			expect(data.size).to be 1
			record = data[0]

			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'
		end

		it 'must ignore cases' do
			data = ADIF.parse_adi("<CALL:6>WN4AZY<BAND:3>20M<MODE:4>RTTY<QSO_DATE:8>19960513<TIME_ON:4>1305<EOR>").records
			expect(data.size).to be 1
			record = data[0]

			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'
		end

		it 'must ignore gabage after data' do
			data = ADIF.parse_adi(<<-EOS).records
			<call:6>WN4AZY
			<band:3>20M
			<mode:4>RTTY
			<qso_date:8>19960513
			<time_on:4>1305
			<eor>
			EOS
			expect(data.size).to be 1
			record = data[0]

			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'
		end

		it 'can parse multiple records' do
			data = ADIF.parse_adi(<<-EOS).records
			<call:6>WN4AZY<band:3>20M<mode:4>RTTY
			<qso_date:8:d>19960513<time_on:4>1305<eor>

			<call:5>N6MRQ<band:2>2M<mode:2>FM
			<qso_date:8:d>19961231<time_on:6>235959<eor>
			EOS
			expect(data.size).to be 2

			record = data[0]
			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'

			record = data[1]
			expect(record[:call]).to eq 'N6MRQ'
			expect(record[:band]).to eq '2M'
			expect(record[:mode]).to eq 'FM'
			expect(record[:qso_date]).to eq '19961231'
			expect(record[:time_on]).to eq '235959'
		end

		it 'can allow header' do
			data = ADIF.parse_adi(<<-EOS).records
			this data was exported using WF1B RTTY version 9, conforming to ADIF standard specification version 9.99
			<eoh>

			<call:6>WN4AZY
			<band:3>20M
			<mode:4>RTTY
			<qso_date:8>19960513
			<time_on:4>1305
			<eor>
			EOS
			expect(data.size).to be 1
			record = data[0]

			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'

			adif = ADIF.parse_adi(<<-EOS)
			Generated on 2011-11-22 at 02:15:23Z for WN4AZY

			<adif_ver:5>3.0.4
			<programid:7>MonoLog
			<USERDEF1:8:N>QRP_ARCI
			<USERDEF2:19:E>SweaterSize,{S,M,L}

			<USERDEF3:15>ShoeSize,{5:20}
			<EOH>

			<call:6>WN4AZY
			<band:3>20M
			<mode:4>RTTY
			<qso_date:8>19960513
			<time_on:4>1305
			<eor>
			EOS

			header = adif.header
			expect(header[:adif_ver]).to eq '3.0.4'
			expect(header[:programid]).to eq 'MonoLog'
			expect(header[:userdef1]).to eq 'QRP_ARCI'
			expect(header[:userdef2]).to eq 'SweaterSize,{S,M,L}'
			expect(header[:userdef3]).to eq 'ShoeSize,{5:20}'

			data = adif.records
			expect(data.size).to be 1
			record = data[0]
			expect(record[:call]).to eq 'WN4AZY'
			expect(record[:band]).to eq '20M'
			expect(record[:mode]).to eq 'RTTY'
			expect(record[:qso_date]).to eq '19960513'
			expect(record[:time_on]).to eq '1305'
		end

		it 'does not include invalid row' do
			expect(ADIF.parse_adi("<CALL:6>WN4AZY").records.size).to be 0
		end

		it 'has datetime_on/datetime_off method for utility' do
			data = ADIF.parse_adi(<<-EOS).records
			<eoh>
			<qso_date:8:d>19960513<time_on:4>1305
			<qso_date_off:8:d>19960513<time_off:4>1310<eor>
			<qso_date:8:d>19961231<time_on:6>235959
			<qso_date_off:8:d>19970101<time_off:6>000005<eor>
			EOS

			record = data[0]
			expect(record.datetime_on).to be_instance_of(DateTime)
			expect(record.datetime_on.strftime('%Y-%m-%d %H:%M:%S')).to eq "1996-05-13 13:05:00"
			expect(record.datetime_off).to be_instance_of(DateTime)
			expect(record.datetime_off.strftime('%Y-%m-%d %H:%M:%S')).to eq "1996-05-13 13:10:00"

			record = data[1]
			expect(record.datetime_on).to be_instance_of(DateTime)
			expect(record.datetime_on.strftime('%Y-%m-%d %H:%M:%S')).to eq "1996-12-31 23:59:59"
			expect(record.datetime_off).to be_instance_of(DateTime)
			expect(record.datetime_off.strftime('%Y-%m-%d %H:%M:%S')).to eq "1997-01-01 00:00:05"
		end
	end

	context "ADX" do
		adif = ADIF.parse_adx(<<-EOS)
			<?xml version="1.0" encoding="UTF-8"?>
			<ADX>
				<HEADER>
					<ADIF_VER>3.0.4</ADIF_VER>
					<PROGRAMID>monolog</PROGRAMID>
					<USERDEF FIELDID="1" TYPE="N">EPC</USERDEF>
					<USERDEF FIELDID="2" TYPE="E" ENUM="{S,M,L}">SWEATERSIZE</USERDEF>
					<USERDEF FIELDID="3" TYPE="N" RANGE="{5:20}">SHOESIZE</USERDEF>
				</HEADER>
				<RECORDS>
					<RECORD>
						<QSO_DATE>19900620</QSO_DATE>
						<TIME_ON>1523</TIME_ON>
						<CALL>VK9NS</CALL>
						<BAND>20M</BAND>
						<MODE>RTTY</MODE>
						<USERDEF FIELDNAME="SWEATERSIZE">M</USERDEF>
						<USERDEF FIELDNAME="SHOESIZE">11</USERDEF>
						<APP PROGRAMID="MONOLOG" FIELDNAME="Compression" TYPE="s">off</APP>
					</RECORD>
					<RECORD>
						<QSO_DATE>20101022</QSO_DATE>
						<TIME_ON>0111</TIME_ON>
						<CALL>ON4UN</CALL>
						<BAND>40M</BAND>
						<MODE>PSK</MODE>
						<SUBMODE>PSK63</SUBMODE>
						<USERDEF FIELDNAME="EPC">32123</USERDEF>
						<APP PROGRAMID="MONOLOG" FIELDNAME="COMPRESSION" TYPE="s">off</APP>
					</RECORD>
				</RECORDS>
			</ADX>
		EOS
		p adif
	end
end

describe ADIF::Writer do

	context "adi" do
		it 'writes an adi stream' do
			io = StringIO.new
			writer = ADIF::Writer.new(io, :adi)
			
			writer << ADIF::Header.new({
				:programid => 'ruby-adif',
				:userdef   => [{ :type => 'E', :enum => '{S,M,L}' }, 'SWEATERSIZE'],
			})
			
			writer << ADIF::Record.new({
				:call => 'JH1UMV',
				:qso_date => '20140624',
				:time_on => '230000',
			})
			
			writer.finish

			readback = ADIF.parse_adi(io.string)
			expect(readback.header[:programid]).to eq 'ruby-adif'
			expect(readback.header[:userdef]).to eq 'SWEATERSIZE'
			expect(readback.records.size).to be 1
			expect(readback.records[0][:call]).to eq 'JH1UMV'
		end
	end
	
	context "adx" do
		it 'writes an adx stream' do
			io = StringIO.new
			writer = ADIF::Writer.new(io, :adx)
			
			writer << ADIF::Header.new({
				:programid => 'ruby-adif',
				:userdef   => [{ :type => 'E', :enum => '{S,M,L}' }, 'SWEATERSIZE'],
			})
			
			writer << ADIF::Record.new({
				:call => 'JH1UMV',
				:qso_date => '20140624',
				:time_on => '230000',
			})
        	
			writer.finish

			# This should work, but does not presently.
			# It is expected https://github.com/cho45/adif/issues/2 will fix this.
			# readback = ADIF.parse_adx(io.string)
		end
	end
end
