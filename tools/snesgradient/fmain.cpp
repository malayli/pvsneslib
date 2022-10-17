//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "fmain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}

//---------------------------------------------------------------------------
void __fastcall TForm1::UpdateDisplay(void)
{
	int i,j,r,g,b,rg,gg,bg;
	unsigned char *srcg,*srcp,*dst1,*dst2;
	bool add,sub,picture,white,black;

	for(i=0;i<224;++i)
	{
		srcg=(unsigned char*)ImageGradient->Picture->Bitmap->ScanLine[i];

		dst1=(unsigned char*)ImageDisplay->Picture->Bitmap->ScanLine[i];
		//dst2=(unsigned char*)ImageDisplay->Picture->Bitmap->ScanLine[i+1];

		bg=*srcg++&0xf8;
		gg=*srcg++&0xf8;
		rg=*srcg  &0xf8;

				b=bg;
				g=gg;
				r=rg;

		for(j=0;j<256;++j)
		{
                /*
			if(picture)
			{
				b=*srcp++&0xf8;
				g=*srcp++&0xf8;
				r=*srcp++&0xf8;
			}

			if(white)
			{
				b=0xf8;
				g=0xf8;
				r=0xf8;
			}

			if(black)
			{
				b=0;
				g=0;
				r=0;
			}

			if(add)
			{
				r+=rg;
				g+=gg;
				b+=bg;

				if(r>0xff) r=0xff;
				if(g>0xff) g=0xff;
				if(b>0xff) b=0xff;
			}

			if(sub)
			{
				r-=rg;
				g-=gg;
				b-=bg;

				if(r<0) r=0;
				if(g<0) g=0;
				if(b<0) b=0;
			}
*/
			*dst1++=b;
			*dst1++=g;
			*dst1++=r;

/*
			*dst1++=b;
			*dst1++=g;
			*dst1++=r;

			*dst2++=b;
			*dst2++=g;
			*dst2++=r;
			*dst2++=b;
			*dst2++=g;
			*dst2++=r;
*/
		}
	}

	ImageDisplay->Repaint();
}

//---------------------------------------------------------------------------
void __fastcall TForm1::SpeedButtonGradientConvertClick(TObject *Sender)
{
	int i,j,k,y,n,m,r,g,b,col;
	int ptr,cnt,prev,wdt,hgt;
	AnsiString str;
	unsigned char* src;
	int pack_color[512];
	int pack_repeat[512];
	int row_len,index,pack_len;

	UpdateDisplay();

//	if(CheckBoxAverageH->Checked) wdt=256; else wdt=1;
        wdt=1;

        hgt=224;

	MemoOutput->Clear();

	pack_len=0;
	prev=-1;
	cnt=1;

	for(i=0;i<hgt;++i)
	{
		n=0;
		r=0;
		g=0;
		b=0;

		src=(unsigned char*)ImageGradient->Picture->Bitmap->ScanLine[i];

			r=*src++;
			g=*src++;
			b=*src++;

                        /*
		for(j=0;j<wdt;++j)
		{
			r+=*src++;
			g+=*src++;
			b+=*src++;
		}

		r/=wdt;
		g/=wdt;
		b/=wdt;*/

		n=(n<<8)|((r>>3)|(0x80>>0));
		n=(n<<8)|((g>>3)|(0x80>>1));
		n=(n<<8)|((b>>3)|(0x80>>2));

		if(i==hgt-1||(i&&n!=prev))//||!CheckBoxPackData->Checked)
		{
			while(cnt)
			{
				if(cnt>127)
				{
					m=127;
					cnt-=127;
				}
				else
				{
					m=cnt;
					cnt=0;
				}

				pack_color [pack_len]=n;
				pack_repeat[pack_len]=m;

				++pack_len;
			}

			prev=n;
			cnt=1;
		}
		else
		{
			++cnt;
		}
	}

	if(RadioButtonTypePalette1->Checked)
	{
		MemoOutput->Lines->Add("hdmaGradient"+EditName->Text+"List:");

		index=UpDownColorIndex->Position;

		row_len=0;
		str="";

		for(i=0;i<pack_len;++i)
		{
			if(row_len>=3)
			{
				MemoOutput->Lines->Add(str);
				row_len=0;
			}

			if(!row_len) str=" .db "; else str+=",";

			col=pack_color[i];//^0xffffff;

			r= col     &31;
			g=(col>>8 )&31;
			b=(col>>16)&31;

			col=r|(g<<5)|(b<<10);       // 2122  ww+++- CGDATA - CGRAM Data write        -bbbbbgg gggrrrrr

			str+="$"+IntToHex(pack_repeat[i],2)+",$"+IntToHex(index,2)+",$"+IntToHex(index,2)+",";
			str+="$"+IntToHex(col&0xff,2)+",";
			str+="$"+IntToHex((col>>8)&0xff,2);

			++row_len;
		}

		MemoOutput->Lines->Add(str);
		MemoOutput->Lines->Add(" .db $00");
		MemoOutput->Lines->Add("");
	}
}

//---------------------------------------------------------------------------
void __fastcall TForm1::SpeedButtonWindowConvertClick(TObject *Sender)
{
        int i,j,k,y,n,m,r,g,b,col;
	int ptr,cnt,prev,wdt,hgt;
	AnsiString str;
	unsigned char* src;
	int pack_repeat[512];
	int row_len,index,pack_len;

	UpdateDisplay();

        wdt=1;
        hgt=224;

	MemoOutput->Clear();

	pack_len=0;
	prev=-1;
	cnt=1;

	for(i=0;i<hgt;++i)
	{
		n=0;
		r=0;
		g=0;
		b=0;

		src=(unsigned char*)ImageGradient->Picture->Bitmap->ScanLine[i];

                for (j=0;j<256;j++) {
                        r=*src++;
	        	g=*src++;
        		b=*src++;
                	n=(n<<8)|((r>>3)|(0x80>>0));
        		n=(n<<8)|((g>>3)|(0x80>>1));
        		n=(n<<8)|((b>>3)|(0x80>>2));
                        r= n     &31;
			g=(n>>8 )&31;
			b=(n>>16)&31;
			col=r|(g<<5)|(b<<10);       // 2122  ww+++- CGDATA - CGRAM Data write        -bbbbbgg gggrrrrr
//                        str=IntToHex(col,8);
  //                      MemoOutput->Lines->Add(str);
                        if (col != 0x007FFF) break;
                }
                pack_repeat[i]=j;
        }
	MemoOutput->Lines->Add("hdmaWindow"+EditName->Text+"LeftList:");
	for(i=0;i<hgt;++i)
	{
                str=",$"+IntToHex(pack_repeat[i],2);
                MemoOutput->Lines->Add(str);
        }
        MemoOutput->Lines->Add(" . db 0xff, 0");

	MemoOutput->Lines->Add("hdmaWindow"+EditName->Text+"RightList:");
	for(i=0;i<hgt;++i)
	{
                str=",$"+IntToHex(256-pack_repeat[i],2);
                MemoOutput->Lines->Add(str);
        }
        MemoOutput->Lines->Add(" . db 0x00, 0");

                   /*
	if(RadioButtonTypePalette1->Checked)
	{
		MemoOutput->Lines->Add("hdmaWindow"+EditName->Text+"List:");

		index=UpDownColorIndex->Position;

		row_len=0;
		str="";

		for(i=0;i<pack_len;++i)
		{
			if(row_len>=3)
			{
				MemoOutput->Lines->Add(str);
				row_len=0;
			}

			if(!row_len) str=" .db "; else str+=",";

			col=pack_color[i];//^0xffffff;

			r= col     &31;
			g=(col>>8 )&31;
			b=(col>>16)&31;

			col=r|(g<<5)|(b<<10);       // 2122  ww+++- CGDATA - CGRAM Data write        -bbbbbgg gggrrrrr

			str+="$"+IntToHex(pack_repeat[i],2)+",$"+IntToHex(index,2)+",$"+IntToHex(index,2)+",";
			str+="$"+IntToHex(col&0xff,2)+",";
			str+="$"+IntToHex((col>>8)&0xff,2);

			++row_len;
		}

		MemoOutput->Lines->Add(str);
		MemoOutput->Lines->Add(" .db $00");
		MemoOutput->Lines->Add("");
	}
        */
}


//---------------------------------------------------------------------------
void __fastcall TForm1::RadioButtonTypePalette1Click(TObject *Sender)
{
        SpeedButtonGradientConvertClick(Sender);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
	ImageDisplay->Picture->Bitmap=new Graphics::TBitmap();
	//ImageDisplay->Picture->Bitmap->SetSize(256,224);
        ImageDisplay->Picture->Bitmap->Width=256;
        ImageDisplay->Picture->Bitmap->Height=256;
	ImageDisplay->Picture->Bitmap->PixelFormat=pf24bit;

	ImageGradient->Picture->Bitmap=new Graphics::TBitmap();
//	ImageGradient->Picture->Bitmap->SetSize(256,224);
        ImageGradient->Picture->Bitmap->Width=256;
        ImageGradient->Picture->Bitmap->Height=256;
	ImageGradient->Picture->Bitmap->PixelFormat=pf24bit;

	ImageDisplay->Picture->Bitmap->Canvas->Brush->Color=clBlack;
	ImageDisplay->Picture->Bitmap->Canvas->FillRect(TRect(0,0,ImageDisplay->Width,ImageDisplay->Height));

      	ImageGradient->Picture->Bitmap->Canvas->Brush->Color=clBlack;
	ImageGradient->Picture->Bitmap->Canvas->FillRect(TRect(0,0,ImageGradient->Width,ImageGradient->Height));
}

//---------------------------------------------------------------------------
void __fastcall TForm1::SpeedButtonGradientReloadClick(TObject *Sender)
{
	if(!FileExists(OpenDialogGradient->FileName)) return;

	ImageGradient->Picture->LoadFromFile(OpenDialogGradient->FileName);

	SpeedButtonGradientConvertClick(Sender);
}

//---------------------------------------------------------------------------
void __fastcall TForm1::SpeedButtonGradientLoadClick(TObject *Sender)
{
	if(!OpenDialogGradient->Execute()) return;

	SpeedButtonGradientReloadClick(Sender);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
        Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::RadioButtonTypeWindowClick(TObject *Sender)
{
        SpeedButtonWindowConvertClick(Sender);
}
//---------------------------------------------------------------------------
