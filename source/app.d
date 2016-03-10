module binaryimageanalyzer;

import std.algorithm;
import std.array;
import std.conv;
import std.digest.crc;
import std.file;
import std.getopt;
import std.algorithm.iteration;
import std.math;
import std.range;
import std.stdio;
import std.string;
import std.traits;

ubyte[T.sizeof] toUBytes(T)(T data)
	if (isIntegral!T || isFloatingPoint!T)
{
	union conv
	{
		T type;
		ubyte[T.sizeof] b;
	}
	conv tb = { type : data };
	return tb.b;
}
/+
interface IBinaryTextEncoding
{
public:
	struct Record
	{
		RecordType type;
		ubyte recordLength;
		uint address;
		ubyte[] data;
		ubyte checksum;
	}

	ubyte[] GetData(uint address);
	//void PutHeader(string data);
	void PutData(uint address, ubyte[] data);
	void SaveImage(string filename);
}


class SRecord : IBinaryImage
{
	enum RecordType : char
	{
		Header = '0',
		Data16bit,
		Data24bit,
		Data32bit,
		Count16bit = '5',
		Count24bit,
		StartAddr32bit,
		StartAddr24bit,
		StartAddr16bit
	}

public:
	this(string file)
	{

	}

	ubyte[] GetData(uint address)
	{

	}

	//void PutHeader(string data);
	void PutData(uint address, ubyte[] data)
	{

	}

	void SaveImage(string filename)
	{

	}

private:

	Record parseRecord(string recordStr)
	{
		Record record;
		RecordType recType;
		int addrSize;
		uint offset = 1;

		switch(recordStr[offset])
		{
			case '0':
				record.type = RecordType.Header;
				addrSize = 2;
				break;
			case '1':
				record.type = RecordType.Data16bit;
				addrSize = 2;
				break;
			case '2':
				record.type = RecordType.Data24bit;
				addrSize = 3;
				break;
			case '3':
				record.type = RecordType.Data32bit;
				addrSize = 4;
				break;
			case '5':
				record.type = RecordType.Count16bit;
				break;
			case '6':
				record.type = RecordType.Count24bit;
				break;
			case '7':
				record.type = RecordType.StartAddr32bit;
				addrSize = 4;
				break;
			case '8':
				record.type = RecordType.StartAddr24bit;
				addrSize = 3;
				break;
			case '9':
				record.type = RecordType.StartAddr16bit;
				addrSize = 2;
				break;
			default:
				break;
		}
		offset++;

		string recLen = recordStr[offset..offset+2];

		record.recordLength = recLen.parse!ubyte(16U);
		offset += 2;

		string addrStr = recordStr[offset..offset+addrSize*2];

		record.address = addrStr.parse!uint(16U);
		offset += addrSize*2;

		record.data = recordStr[0..$-2].toUbytes(offset);

		return record;
	}

}
+/
enum RecordType : char
{
	Header = '0',
	Data16bit,
	Data24bit,
	Data32bit,
	Count16bit = '5',
	Count24bit,
	StartAddr32bit,
	StartAddr24bit,
	StartAddr16bit
}

struct Record
{
	RecordType type;
	ubyte recordLength;
	uint address;
	ubyte[] data;
	ubyte checksum;
}

ubyte[] toUbytes(string dataStr, ref uint offset)
{
	ubyte[] arr = new ubyte[(dataStr.length - offset)/2];

	foreach(ref el; arr)
	{
		string str = dataStr[offset..offset+2];

		offset += 2;
		el = str.parse!ubyte(16U);
	}

	return arr;
}

Record parseRecord(string recordStr)
{
	Record record;
	RecordType recType;
	int addrSize;
	uint offset = 1;

	switch(recordStr[offset])
	{
		case '0':
			record.type = RecordType.Header;
			addrSize = 2;
			break;
		case '1':
			record.type = RecordType.Data16bit;
			addrSize = 2;
			break;
		case '2':
			record.type = RecordType.Data24bit;
			addrSize = 3;
			break;
		case '3':
			record.type = RecordType.Data32bit;
			addrSize = 4;
			break;
		case '5':
			record.type = RecordType.Count16bit;
			break;
		case '6':
			record.type = RecordType.Count24bit;
			break;
		case '7':
			record.type = RecordType.StartAddr32bit;
			addrSize = 4;
			break;
		case '8':
			record.type = RecordType.StartAddr24bit;
			addrSize = 3;
			break;
		case '9':
			record.type = RecordType.StartAddr16bit;
			addrSize = 2;
			break;
		default:
			break;
	}
	offset++;

	string recLen = recordStr[offset..offset+2];

	record.recordLength = recLen.parse!ubyte(16U);
	offset += 2;

	string addrStr = recordStr[offset..offset+addrSize*2];

	record.address = addrStr.parse!uint(16U);
	offset += addrSize*2;

	record.data = recordStr[0..$-2].toUbytes(offset);

	return record;
}

void printHelp()
{
	writeln("BinaryImageAnalyzer options: ");
	writeln("\t--file\t\tfile to read or generate");
	writeln("\t--gen\t\tgenerate an s19 file");
	writeln("\t--address\tstarting address for generated file (use 0x if in hex)");
	writeln("\t\t\tdefault: 0xFE8000");
	writeln("\t--size\t\tsize of generated file (use 0x if in hex)");
	writeln("\t\t\tdefault: 0x10000");
	writeln("\t--help\t\tprints this message");
}

string addrToString(Record record)
{
	if((record.type == RecordType.Header) || (record.type == RecordType.Data16bit) || (record.type == RecordType.StartAddr16bit))
	{
		return record.address.toChars!(16, char, LetterCase.upper).array.rightJustify(4, '0').leftJustify(8, ' ');
	}
	else if((record.type == RecordType.Data24bit) || (record.type == RecordType.StartAddr24bit))
	{
		return record.address.toChars!(16, char, LetterCase.upper).array.rightJustify(6, '0').leftJustify(8, ' ');
	}
	else if((record.type == RecordType.Data32bit) || (record.type == RecordType.StartAddr32bit))
	{
		return record.address.toChars!(16, char, LetterCase.upper).array.rightJustify(8, '0');
	}
	assert(0);
}

void main(string[] args)
{
	string addressStr, sizeStr;
	string fileName;
	bool generate;

	auto res = getopt(args, "file|f", "file to read or generate", &fileName,
							"gen|g", "generate an s19 file", &generate,
							"address|a", "starting address for generated file (use 0x if in hex). default: 0xFE8000", &addressStr, 
							"size|s", "size of generated file (use 0x if in hex). default: 0x10000", &sizeStr);

	if(res.helpWanted)
	{
		writeln("BinaryImageAnalyzer options:");
		foreach(opt; res.options)
		{
			writeln(opt.optShort, " | ", opt.optLong, "\t\t", opt.help);
		}
		return;
	}

	if(fileName == "")
	{
		writeln("no input file, exiting");
		return;
	}

	if(!generate)
	{
		if(!exists(fileName))
		{
			writeln("file ", fileName, " does not exist. Exiting");
			return;
		}

		writeln("Analyzing ", fileName);

		string file = to!string(read(fileName));

		string[] textRecords = file.splitLines;

		Record[] records = new Record[textRecords.length];

		uint totalBytes = 0;
		foreach(int i, immutable record; textRecords)
		{
			records[i] = record.parseRecord;
			if((records[i].type == RecordType.Data16bit) || (records[i].type == RecordType.Data24bit) || (records[i].type == RecordType.Data32bit))
			{
				totalBytes += records[i].recordLength;
			}
		}

		foreach(record; records)
		{
			string dataStr;
			foreach(immutable el; record.data)
			{
				dataStr ~= toChars!(16, char, LetterCase.upper)(cast(immutable uint)el).array.rightJustify(2, '0') ~ " ";
			}

			if(record.type == RecordType.Header)
			{
				writeln("header: ", cast(char[])record.data);
			}
			else
			{
				writeln("S"~record.type~"  "~record.recordLength.to!string, "\t0x", record.addrToString, "\t", dataStr);
			}
		}
		writeln("Total data bytes: ", totalBytes);
	}
	else
	{
		import std.bitmanip : nativeToLittleEndian, nativeToBigEndian;
		ubyte[] data = new ubyte[ushort.max];
		string output;

		foreach(uint i, ref el; data)
		{
			el = cast(ubyte)i;
		}

		uint sum = 0;
		foreach(el; data)
		{
			sum += cast(uint)el;
		}

		data ~= nativeToLittleEndian(~sum);
		CRC32 crc32;
		foreach(chunk; data.chunks(4))
		{
			reverse(chunk);
			crc32.put(chunk);
		}
		//auto crc = crc32Of(data);
		auto crc = crc32.finish;
		data ~= crc;

		uint address = 0xFE8000;
		uint bytesPerRecord = 32;
		uint imageSize = 0x10000;
		
		if(addressStr != "")
		{
			if(addressStr.canFind("0x"))
			{
				string tmp = addressStr[2..$];
				address = tmp.parse!uint(16);
			}
			else
			{
				address = addressStr.parse!uint;
			}
		}
		if(sizeStr != "")
		{
			if(sizeStr.canFind("0x"))
			{
				string tmp = sizeStr[2..$];
				imageSize = tmp.parse!uint(16);
			}
			else
			{
				imageSize = sizeStr.parse!uint;
			}
		}
		
		// account for checksum and crc
		imageSize += 8;

		writeln("address is: ", address);

		uint numRecords = to!uint(ceil(cast(double)imageSize/cast(double)bytesPerRecord));
		uint offset = 0;


		string headerInfo = "Test image generated by BinaryImageAnalyzer: "~fileName;
		//char[] bytes = 
		output = "S0030000FC\n";

		foreach(int i; 0..numRecords-1)
		{
			uint[36] tmpData;
			tmpData[0] = 36;
			//auto addr = toUBytes(address)[0..$-1];
			auto addr = nativeToBigEndian(address)[1..$];
			//reverse(addr);
			tmpData[1..4] = to!(uint[])(addr);
			tmpData[4..$] = to!(uint[])(data[offset..offset+32]);
			offset += 32;

			uint checksum = 0;
			string rec = `S2`;

			foreach(el; tmpData)
			{
				checksum += el;
				rec ~= toChars!(16, char, LetterCase.upper)(el).array.rightJustify(2,'0');
			}

			checksum &= 0xFF;		
			checksum = (~checksum) & 0xFF;
			
			rec ~= toChars!(16, char, LetterCase.upper)(checksum).array.rightJustify(2,'0');

			output ~= rec~'\n';
			address += 32;
		}

		output ~= "S2";

		uint[12] tmpData;
		tmpData[0] = 12;
		auto addr = nativeToBigEndian(address)[1..$];
		tmpData[1..4] = to!(uint[])(addr);
		tmpData[4..8] = to!(uint[])(cast(ubyte[])nativeToBigEndian(~sum));
		tmpData[8..$] = to!(uint[])(cast(ubyte[])crc);

		uint checksum = 0;
		foreach(el; tmpData)
		{
			checksum += el;
			output ~= toChars!(16, char, LetterCase.upper)(el).array.rightJustify(2,'0');
		}
		checksum &= 0xFF;		
		checksum = (~checksum) & 0xFF;

		output ~= toChars!(16, char, LetterCase.upper)(checksum).array.rightJustify(2,'0') ~ "\n";

		output ~= "S9030000FC\n";

		std.file.write(fileName, output);
	}
}
