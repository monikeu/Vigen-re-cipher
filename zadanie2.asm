;Zadanie 1 - Prezentacja funckji klucza publicznego w postaci grafiki ASCII
;Modyfikacja - zamiana półbajtów
;autor: Monika Darosz


dane segment

	argumenty  		db 128 dup (?) ; miejsce na argumenty wpisane do programu
	offsetarg   	db 128 dup (?) ; offsety początku kolejnych argumentów
	ilearg 			db  0			
	dlargumentow	db 128 dup (?) ; dugości poszczególnych argumentów
	dlarg 			db 0 			; długość pojedynczego argumentu
	
	error0 db "Brak argumentow! " , 13, 10, '$'
	error1 db "Zla liczba argumentow", 13,10, '$'
	error2 db "Zła postać 1 argumentu", 13, 10, '$'
	error3 db "Blad otwarcia pliku", 13, 10, '$'
	opcja 	db 0
	
	input db 100 dup (?) ;nazwa pliku wejsciowego
	output db 100 dup (?)	;---||---- wyjsciowego
	kod db 100 dup (?) ; 
	
	uchwyt_input dw ?
	uchwyt_output dw ?
	
	bufor_odczytu db 1024 dup (?)
	bufor_zapisu db 1024 dup (?)
	
	dlkodu db 0
	dlbufora dw 0 ;dl bufor_odczytu
	
dane ends

code segment

	start:	

		mov sp, offset wstosu       ; inicjalizacja stosu
		mov ax, seg wstosu
		mov ss, ax 
		
		call czy_sa_argumenty
		call trzy_czy_cztery_arg
		call opcja_1_czy_2 
		
		call otworz_plik_do_odczytu
		call otworz_plik_do_zapisu
	
		call petla_wczytujaca
		
		call zamknij_plik_input
		call zamknij_plik_output
		
	
	
		call koniec
	
;//////////////////////////////////////////////////////PROCEDURY////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
	czy_sa_argumenty: ;sprawdza czy są jakiekolwiek argumenty
		push bx	
			mov bx,0     				
			mov bl, byte ptr es:[080h] 	
		
			cmp bx, 1h 					
			ja wykryto_arg 				; A>B
		pop bx	
			call nie_ma_argumentow		; jeśli nie ma arg
			koniec_wykryto_arg:
		pop bx
	ret
	
	nie_ma_argumentow: ;wypisuje stosowny komunikat
		push ds
		push dx
			mov ax, seg error0  		 
			mov ds,ax
			mov dx, offset error0
		
			call print
		pop dx
		pop ds
			call koniec
	ret
	
	koniec:  ; koniec programu
		mov ax,04c00h 				
		int 21h
	
	print:  ;wypisywanie
		mov ah, 9h 					
		int 21h 					
	ret
	
	wykryto_arg: ; uruchomiona tylko wtedy, gdy zostaną wykryte argumenty    
		push ds
		push si
		push di
		push cx
			mov	ax, seg argumenty 			
			mov	ds, ax       
			mov	si, 0 		;   si będzie iterować po kolejnych miejscach ciągu bajtów "argumenty"

			mov cx, 0 				
			
			mov cx, bx 		;w BX - ilość argumentów w buforze , w CX (licznik) - ilosc powtorzen    
			
			dec bx
			mov di, bx
			mov byte ptr es:[082h+di], 20h ; wstawiam spację zamiast entera na koniec bufora
			
			mov di, 0 
			mov bx, 0 		
			mov ax, 0		
			
			call wczytaj_z_przerwami
		pop cx
		pop di
		pop si
		pop ds
	jmp koniec_wykryto_arg
	
	
	wczytaj_z_przerwami: ; wczytuje argumenty do 'argumenty' w  postaci "arg$arg$arg$" itd. 					
		wczyt_znak:	
		
			mov al, byte ptr es:[082h+di] 					; di iteruje po buforze
		
			jmp czy_bialy 									;sprawdzam czy znak jest biały, jeśli jest powrót nastąpi do etykiety "idz_na_kon"
			koniec_czy_bialy:
			
			cmp bl, 0d										; w bl  - informacja o poprzednim znaku, (znak 'zerowy' ustawiony na biały)
			
			je offset_poczatku_i_zliczanie       		 ; skok jeśli poprzedni znak był biały, a obecny jest nie-biały (czyli początek argumentu)
			koniec_offset_poczatku_i_zliczanie:	
			
			mov byte ptr ds:[argumenty+si], al 				; si iteruje po 'argumenty'	
			inc di 						
			inc si						
			inc ds:[dlarg] 				
			
			mov bl, 1d
			idz_na_kon:					; koniec procedury 'zjedz_bialy'
		
		
		loop  wczyt_znak                      
	ret
	
	czy_bialy: ; sprawdza czy znak jest biały 
		cmp al, 20h		
		je zjedz_bialy  
			
		cmp al , 9d
		je zjedz_bialy
	jmp koniec_czy_bialy
	
	zjedz_bialy: ; zjada białe znaki
			inc di  							
					cmp bl,1d
					je wstaw_przerwe
					koniec_wstaw_przerwe:
					
					cmp bl, 1d
					je dl_arg    ; zapisuje długośc arguemntu
					koniec_dl_arg:
			mov bl, 0d
	jmp idz_na_kon
	
	wstaw_przerwe: ; wstawia między argumenty $
		mov al , '$'
		mov byte ptr ds:[argumenty+si], al
		inc si
	jmp koniec_wstaw_przerwe
	
	dl_arg: ;zapisuje długości kolejnych argumentów w "dlargumentow", zeruje "dlarg" 
		push bx
		push ax
		push di
			mov al, byte ptr ds:[ilearg]	;  do al ilość argumentów
			mov ah, 0 						
			mov di, ax						;  do di ilość argumentów
				
			mov al, byte ptr ds:[dlarg]					;do al długość argumentu
			mov byte ptr ds:[dlargumentow+di],al
		
			mov ds:[dlarg], 0
		
		pop di
		pop ax
		pop bx
	jmp koniec_dl_arg
	
	offset_poczatku_i_zliczanie: ; zapisuje offset początku argumentu w "offsetarg" i zlicza argumenty w "ilearg"
	push bx
	push ax
	push di
		inc ds:[ilearg]
		mov al, byte ptr ds:[ilearg]	;  do al ilość argumentów
		mov ah, 0 						
		mov bx, si						;  do bx offset początku argumentu
		mov di, ax						;  do di ilość argumentów
		mov byte ptr ds:[offsetarg+di], bl	
		
	pop di
	pop ax
	pop bx
	jmp koniec_offset_poczatku_i_zliczanie
	
	funkcja_ile_arg: ;zwraca ilość argumentów w al
	push ds
	    mov ax, seg ilearg
	    mov ds, ax
		mov al, ds:[ilearg]
	pop ds
	ret
	
	funkcja_offset_arg_o_nr: ;przyjmuje w ax numer argumentu, zwraca w al jego offset
		push di
		push ds
			mov di, ax
		    mov ax, seg offsetarg
		    mov ds, ax
			mov al, byte ptr ds:[offsetarg+di]
		pop ds
		pop di
	ret
	
	funkcja_dl_arg_o_nr: ;przyjmuje w ax numer argumentu, zwraca w al jego długość
		push di
		push ds
			mov di, ax
			mov ax, seg dlargumentow
			mov ds, ax
			mov al, byte ptr ds:[dlargumentow+di]
		pop ds
		pop di
	ret
	
	trzy_czy_cztery_arg: ; sprawdza czy wpisano odpowiednia liczbę argumentów
		mov ax,0
		call funkcja_ile_arg
		cmp al, 3d
		je argumenty_sa_ok
		cmp al, 4d
		je cztery_arg
	push dx ; jesli liczba argumentów nie jest ani 3 ani 4 
	push ds
	    mov ax, seg error1
	    mov ds, ax
		mov dx, offset error1
		call print
	pop ds
	pop dx
		call koniec
		argumenty_sa_ok:
ret
	
cztery_arg: ;gdy są cztery arg, sprawdza poprawność pierwszego
	push di
	push ds
		mov ax, 1
		call funkcja_offset_arg_o_nr
		mov ah,0
		mov di, ax 
		
		mov ax, seg argumenty
		mov ds, ax
		
		mov al, byte ptr ds:[argumenty+di]
		cmp al, 45d ; kod ascii -
		jne bledny_1arg        
		inc di
		mov al, byte ptr ds:[argumenty+di]
		cmp al, 100d  ; kod ascii d
		jne bledny_1arg	
		
		mov ax, 1   ; sprawdzam czy 1. argument ma długość 2
		call funkcja_dl_arg_o_nr
		cmp al, 2
		jne bledny_1arg
		
	pop ds
	pop di
jmp argumenty_sa_ok

bledny_1arg: ; sprawdza czy 1. arg to "-d" (tylko jesli są 4 arg)
	push dx
	push ds
		mov ax, seg error2
		mov ds, ax
		mov dx, offset error2
		call print
	pop ds
	pop dx
		call koniec

opcja_1_czy_2: 
	call funkcja_ile_arg	
	cmp al, 4 
	je opcja2 ; przepisuje do input i output odpowiednie argumenty 
	jmp opcja1  
	koniec_opcja1_opcja2:
ret

opcja1:
	push bx
		;przepisuje do input
		mov ax, 1
		call funkcja_dl_arg_o_nr
		mov bl, al
		
		mov ax, 1 
		call funkcja_offset_arg_o_nr; w al początek offsetu arg
		mov ah, bl ; w ah dlugosc argumentu
		mov bx, offset input ; w bx offset poczatku miejsca do którego przepisujemy
		call przepisz_arg
		
		;przepisywanie do output
		mov ax, 2 
		call funkcja_dl_arg_o_nr
		mov bl, al
		
		mov ax,2 
		call funkcja_offset_arg_o_nr; w al początek offsetu arg
		mov ah, bl ; w ah dlugosc argumentu
		mov bx, offset output ; w bx offset poczatku miejsca do którego przepisujemy
		call przepisz_arg
		
		mov ax, 3
		call przepisz_kod
		
		mov ax, seg dlkodu ; zapisuje długośc kodu 
		mov ds, ax
		mov ax, 3
		call funkcja_dl_arg_o_nr
		mov ds:[dlkodu], al
		
	pop bx
jmp koniec_opcja1_opcja2

opcja2:
	push bx
	push ds
		;przepisuje do input
		mov ax, 2
		call funkcja_dl_arg_o_nr
		mov bl, al
		
		mov ax, 2
		call funkcja_offset_arg_o_nr; w al początek offsetu arg
		mov ah, bl ; w ah dlugosc argumentu
		mov bx, offset input ; w bx offset poczatku miejsca do którego przepisujemy
		call przepisz_arg
		
		;przepisywanie do output
		mov ax, 3 
		call funkcja_dl_arg_o_nr
		mov bl, al
		
		mov ax, 3
		call funkcja_offset_arg_o_nr; w al początek offsetu arg
		mov ah, bl ; w ah dlugosc argumentu
		mov bx, offset output ; w bx offset poczatku miejsca do którego przepisujemy
		call przepisz_arg
		
		mov ax, 4
		call przepisz_kod
		
		mov ax, seg dlkodu ; zapisuje długośc kodu 
		mov ds, ax
		mov ax, 4
		call funkcja_dl_arg_o_nr
		mov ds:[dlkodu], al
		
		mov ax, seg opcja
		mov ds, ax
		mov ds:[opcja], 1
	pop ds
	pop bx
jmp koniec_opcja1_opcja2


przepisz_kod: ; przyjmuje w ax numer argumentu, którym jest kod
	push cx
	push bx
		mov bx, ax ; kopiuje numer argumentu do bx
		call funkcja_dl_arg_o_nr
		mov ch, al ; kopiuje do ch dlugosc arg
	
		mov ax, bx ; numer arg spowrotem do ax
		call funkcja_offset_arg_o_nr ; zwróci w al offset argumentu
		
		mov ah,ch ; do ah długość argumentu
		mov bx, offset kod
		
		call przepisz_arg
	pop bx
	pop cx
ret

przepisz_arg: ; przyjmuje w al początek offsetu argumentu, w ah dlugosc argumentu, w bx offset miejsca do którego przepisujemy
	push di
	push cx
	push si
	push ds
		mov di, bx
		mov cx, 0
		mov cl,ah ; do cl długość argumentu do przepisania
		mov ah, 0
		mov si, ax ; do si początek offsetu argumentu w obrębie argumenty
		mov di, bx ; do di poczatek miejsca w pamięci do którego przepisujemy
		
		mov ax, seg argumenty
		mov ds, ax
		
		przepisz_po_znaku:
			mov al, ds:[argumenty+si]
			mov ds:[di], al
			inc si
			inc di
		loop przepisz_po_znaku
		
	pop ds	
	pop si
	pop cx
	pop di
ret
	
otworz_plik_do_odczytu:
	push ds	 			
	push dx
		mov ax, seg input
		mov ds, ax
		mov al, 0   ; 0 - tryb odczytu
		mov dx, offset input
		
		mov ah, 3dh; funkcja przerwania 21h otwierająca plik
		int 21h
		
		mov ds:[uchwyt_input], ax ; w di offset odpowiedniego pliku, do którego uchwyt zapisujemy
		
		jc blad_otwarcia ; jeśli CF==1 nastąpił błąd odczytu pliku 
		powrot_blad_otwarcia:
	pop dx	
	pop ds
ret

blad_otwarcia:
	push ds
	push dx
		mov ax, seg error3
		mov ds, ax
		mov dx, offset error3
		call print
	pop dx
	pop ds
jmp powrot_blad_otwarcia

czytaj_z_pliku:
	push cx
	push dx
	push ds
	push bx
		mov ax, seg uchwyt_input
		mov ds, ax
		mov bx, ds:[uchwyt_input]   ; w bx uchwyt do istniejącego pliku
		mov cx, 100			; w cx ilosc bajtow do odczytania
		mov dx, offset bufor_odczytu
		mov ax, seg bufor_odczytu
		mov ds, ax			; ds:[dx] adres bufora
		mov ah, 3fh
		int 21h
		
		mov bx, ax
		mov ax, seg dlbufora
		mov ds, ax
		mov ds:[dlbufora], bx ; długość bufora
	pop bx
	pop ds
	pop dx
	pop cx 
ret

otworz_plik_do_zapisu: ; getchar
	push ds	 			
	push dx
		mov ax, seg output
		mov ds, ax
		mov al, 1   ; 1 - tryb zapisuje
		mov dx, offset output
		
		mov ah, 3dh; funkcja przerwania 21h otwierająca plik
		int 21h
		
		mov ds:[uchwyt_output], ax ; w di offset odpowiedniego pliku, do którego uchwyt zapisujemy
		
		jc blad_otwarcia2 ; jeśli CF==1 nastąpił błąd odczytu pliku 
		powrot_blad_otwarcia2:
	pop dx	
	pop ds
ret

blad_otwarcia2:
	push ds
	push dx
		mov ax, seg error3
		mov ds, ax
		mov dx, offset error3
		call print
	pop dx
	pop ds
jmp powrot_blad_otwarcia2
	
zapisz_do_pliku: ;putchar
	push cx
	push dx
	push ds
	push bx
		mov ax, seg uchwyt_output
		mov ds, ax
		mov bx, ds:[uchwyt_output]   ; w bx uchwyt do istniejącego pliku
		
		mov ax, seg dlbufora
		mov ds, ax
		
		mov cx, ds:[dlbufora]			; w cx ilosc bajtow do zapisania
		mov dx, offset bufor_zapisu
		mov ax, seg bufor_zapisu
		mov ds, ax			; ds:[dx] adres bufora
		mov ah, 40h
		int 21h
	pop bx
	pop ds
	pop dx
	pop cx 
ret

zamknij_plik_input:
	push ds
	push dx
	push bx
		mov ax, seg uchwyt_input
		mov ds, ax
		mov bx, ds:[uchwyt_input]
		mov ah, 3eh
		int 21h
	pop bx
	pop dx
	pop ds
ret

zamknij_plik_output:
	push ds
	push dx
	push bx
		mov ax, seg uchwyt_output
		mov ds, ax
		mov bx, ds:[uchwyt_output]
		mov ah, 3eh
		int 21h
	pop bx
	pop dx
	pop ds
ret

szyfrowanie_czy_deszyfrowanie:
	push ds
		mov ax, seg opcja
		mov ds, ax
		cmp ds:[opcja], 0 
		je szyfrowanie
		cmp ds:[opcja], 1 
		je deszyfrowanie
		powrot_szyfrowanie_deszyfrowanie:
	pop ds
ret

szyfrowanie: ; przyjmuje w ax ilośc znaków z bufora wejsciowego
	push ds
	push cx
	push si
		mov ax, seg dlbufora
		mov ds, ax
		mov cx, ds:[dlbufora]
		mov si, 0
	
		szyfruj_znak:
			push di
			push cx
			push dx
				mov ax, seg dlkodu
				mov ds, ax
				mov cx, 0 
				mov cl, ds:[dlkodu]
				mov di,0
				szyfruj_znak_petla_po_kodzie:
					mov ax, seg kod
					mov ds, ax
					mov bl, ds:[kod+di] ; w bx jeden znak z kodu
					mov bh, 0 
						push bx	; znak z kodu na stos
					
					mov ax, seg bufor_odczytu
					mov ds, ax
					mov bl, ds:[bufor_odczytu+si] ; w bx jedne znak z buforu
					mov bh, 0
						pop ax ; teraz w ax jeden znak z kodu
						
					add ax, bx ;  K+B 
					
					sprawdz_czy_znak_ok:
						cmp ax, 256
						jb znak_ok ; <
						sub ax, 256
					jmp sprawdz_czy_znak_ok
						znak_ok:
						
						mov ds:[bufor_zapisu+si], al
					inc di
					inc si
					cmp si, ds:[dlbufora] ; szyfruje tyle znaków ile jest w buforze_odczytu
					jae koniec_petli ; >= w si ilość wykonanych pętli-1,
					
				loop szyfruj_znak_petla_po_kodzie
			
			pop dx
			pop cx
			sub cx, 2d ; odejmuje, gdyż w obrębie pętli wewnętrznej wykonały się 3 pętle, zewnętrznej 1, 3-1=2
			pop di
		loop szyfruj_znak
	koniec_petli: 
	pop dx
	pop cx ; popy pomini뵥 przy skoku
	pop di
	
	pop si
	pop cx
	pop ds
;ret
jmp powrot_szyfrowanie_deszyfrowanie

deszyfrowanie: 
	push ds
	push cx
	push si
		mov ax, seg dlbufora
		mov ds, ax
		mov cx, ds:[dlbufora]
		mov si, 0
	
		deszyfruj_znak:
			push di
			push cx
			push dx
				mov ax, seg dlkodu
				mov ds, ax
				mov cx, 0 
				mov cl, ds:[dlkodu]
				mov di,0
				deszyfruj_znak_petla_po_kodzie:
					mov ax, seg kod
					mov ds, ax
					mov bl, ds:[kod+di] ; w bx jeden znak z kodu
					mov bh, 0
						push bx ; jeden znak z kodu na stos
						
					mov ax, seg bufor_odczytu
					mov ds, ax
					mov bl, ds:[bufor_odczytu+si]
					mov bh, 0 ; w bx jeden znak z bufor_odczytu
						pop ax ; teraz jeden znak z kodu w ax 
					
					add bx, 256 ; B+256
					sub bx, ax ; B+256-K
					mov ax, bx ;
					
					sprawdz_czy_znak_ok2:
						cmp ax, 256
						jb znak_ok2 ; <
						sub ax, 256
					jmp sprawdz_czy_znak_ok2
						znak_ok2:
						
						mov ds:[bufor_zapisu+si], al
					inc di
					inc si
					cmp si, ds:[dlbufora] ; deszyfruje tyle znaków ile jest w buforze_odczytu
					jae koniec_petli2 ; >= w si ilość wykonanych pętli-1,
					
				loop deszyfruj_znak_petla_po_kodzie
			
			pop dx 
			pop cx
			sub cx, 2d
			pop di
		loop deszyfruj_znak
	koniec_petli2: 
	pop dx
	pop cx ; popy pomini뵥 przy skoku
	pop di
	
	pop si
	pop cx
	pop ds
;ret
jmp powrot_szyfrowanie_deszyfrowanie

petla_wczytujaca:
	push ds
		wczytaj_jeden_bufor:
			call czytaj_z_pliku
			
			mov ax, seg dlbufora ; jesli poprzedni bufor był 100 a ten jest 0
			mov ds, ax
			cmp ds:[dlbufora], 0
			je skoncz_wczytywanie
			
			call szyfrowanie_czy_deszyfrowanie
				
			call zapisz_do_pliku
			
			mov ax, seg dlbufora
			mov ds, ax
			cmp ds:[dlbufora], 100
			jb skoncz_wczytywanie
			
		jmp wczytaj_jeden_bufor
	
	skoncz_wczytywanie:
	pop ds
ret


code ends

stos1 segment stack ; segment stosu

	dw    200 dup(?)
	wstosu    dw ?

stos1 ends

end start