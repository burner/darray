module darray;

import std.array : back;

import exceptionhandling;

struct DArraySlice(FSA,T) {
	FSA* fsa;
	short low;
	short high;

	pragma(inline, true)
	this(FSA* fsa, short low, short high) {
		this.fsa = fsa;
		this.low = low;
		this.high = high;
	}

	pragma(inline, true)
	@property bool empty() const pure @safe nothrow @nogc {
		return this.low >= this.high;
	}

	pragma(inline, true)
	@property size_t length() pure @safe nothrow @nogc {
		return cast(size_t)(this.high - this.low);
	}

	pragma(inline, true)
	@property ref T front() @nogc {
		return (*this.fsa)[cast(size_t)this.low];
	}

	pragma(inline, true)
	@property ref const(T) front() const @nogc {
		return (*this.fsa)[cast(size_t)this.low];
	}

	pragma(inline, true)
	@property ref T back() @nogc {
		return (*this.fsa)[cast(size_t)(this.high - 1)];
	}

	pragma(inline, true)
	@property ref const(T) back() const @nogc {
		return (*this.fsa)[cast(size_t)(this.high - 1)];
	}

	pragma(inline, true)
	void insertBack(S)(auto ref S s) {
		(*this.fsa).insertBack(s);
	}

	/// Ditto
	alias put = insertBack;

	pragma(inline, true)
	ref T opIndex(const size_t idx) @nogc {
		return (*this.fsa)[this.low + idx];
	}

	pragma(inline, true)
	void popFront() pure @safe nothrow @nogc {
		++this.low;
	}

	pragma(inline, true)
	void popBack() pure @safe nothrow @nogc {
		--this.high;
	}

	pragma(inline, true)
	@property typeof(this) save() pure @safe nothrow @nogc {
		return this;
	}

	pragma(inline, true)
	@property const(typeof(this)) save() const pure @safe nothrow @nogc {
		return this;
	}

	pragma(inline, true)
	typeof(this) opIndex() pure @safe nothrow @nogc {
		return this;
	}

	pragma(inline, true)
	typeof(this) opIndex(size_t l, size_t h) pure @safe nothrow @nogc {
		return this.opSlice(l, h);
	}

	pragma(inline, true)
	typeof(this) opSlice(size_t l, size_t h) pure @safe nothrow @nogc {
		assert(l <= h);
		return typeof(this)(this.fsa, 
				cast(short)(this.low + l),
				cast(short)(this.low + h)
			);
	}
}

struct DArray(T) {
	import std.traits;

	T[] data;
	long base;
	long len;

	private void buildCapacity() {
		if(this.len + 1 >= this.data.length) {
			this.data.length = (this.data.length + 10) * 2;
		}
	}

	pragma(inline, true)
	this(Args...)(Args args) {
		foreach(it; args) {
			static if(isAssignable!(T,typeof(it))) {
				this.insertBack(it);
			}
		}
	}

	pragma(inline, true)
	size_t capacity() const @nogc @safe pure nothrow {
		return this.data.length;
	}

	/** This function inserts an `S` element at the back if there is space.
	Otherwise the behaviour is undefined.
	*/
	pragma(inline, true)
	void insertBack(S)(auto ref S t) @trusted if(is(Unqual!(S) == T)) {
		this.buildCapacity();

		this.data[
			cast(size_t)((this.base + this.len) %
				this.data.length)
		] = t;
		++this.len;
	}

	/// Ditto
	pragma(inline, true)
	void insertBack(S)(auto ref S s) @trusted if(!is(Unqual!(S) == T)) {
		this.buildCapacity();
		this.data[
			cast(size_t)((this.base + this.len) %
				this.len)
		] = s;
	}

	/// Ditto
	pragma(inline, true)
	void insertBack(S)(auto ref S defaultValue, size_t num) {
		for(size_t i = 0; i < num; ++i) {
			this.insertBack(defaultValue);
		}
	}
	/** This function inserts an `S` element at the front if there is space.
	Otherwise the behaviour is undefined.
	*/
	pragma(inline, true)
	void insertFront(S)(auto ref S t) @trusted if(is(Unqual!(S) == T)) {
		this.buildCapacity();
		--this.base;
		if(this.base < 0) {
			this.base =
				cast(typeof(this.base))(this.data.length - 1);
		}

		this.data[cast(size_t)this.base] = t;
		++this.len;
	}

	/** This function removes an element form the back of the array.
	*/
	pragma(inline, true)
	void removeBack() {
		assert(!this.empty);

		--this.len;
	}

	/** This function removes an element form the front of the array.
	*/
	pragma(inline, true)
	void removeFront() {
		assert(!this.empty);

		//this.begin = (this.begin + T.sizeof) % (Size * T.sizeof);
		++this.base;
		if(this.base >= this.data.length) {
			this.base = 0;
		}
		--this.len;
	}

	/** This function removes all elements from the array.
	*/
	pragma(inline, true)
	void removeAll() {
		while(!this.empty) {
			this.removeBack();
		}
	}

	pragma(inline, true)
	void remove(ulong idx) {
		import std.stdio;
		if(idx == 0) {
			this.removeFront();
		} else if(idx == this.length - 1) {
			this.removeBack();
		} else {
			for(long i = idx + 1; i < this.length; ++i) {
				this[cast(size_t)(i - 1)] = this[cast(size_t)i];
			}
			this.removeBack();
		}
	}

	/** Access the last or the first element of the array.
	*/
	pragma(inline, true)
	@property ref T back() @trusted @nogc {
		debug ensure(!this.empty);
		return this.data[
			cast(size_t)(this.base + this.len - 1) % this.data.length
		];
	}

	pragma(inline, true)
	@property ref const(T) back() const @trusted @nogc {
		debug ensure(!this.empty);
		return this.data[
			cast(size_t)(this.base + this.len - 1) % this.data.length
		];
	}

	/// Ditto
	pragma(inline, true)
	@property ref T front() @trusted @nogc {
		debug ensure(!this.empty);
		return this.data[cast(size_t)this.base];
	}

	pragma(inline, true)
	@property ref const(T) front() const @trusted @nogc {
		debug ensure(!this.empty);
		return this.data[cast(size_t)this.base];
	}

	/** Use an index to access the array.
	*/
	pragma(inline, true)
	ref T opIndex(const size_t idx) @trusted @nogc {
		debug ensure(idx < this.length);
		return this.data[cast(size_t)((this.base + idx) % this.data.length)];
	}

	/// Ditto
	pragma(inline, true)
	ref const(T) opIndex(const size_t idx) @trusted const @nogc {
		debug ensure(idx < this.length);
		return this.data[cast(size_t)((this.base + idx) % this.data.length)];
	}


	pragma(inline, true)
	DArraySlice!(typeof(this),T) opSlice() pure @nogc @safe nothrow {
		return DArraySlice!(typeof(this),T)(&this, cast(short)0, 
				cast(short)this.length
		);
	}
	
	pragma(inline, true)
	DArraySlice!(typeof(this),T) opSlice(const size_t low, 
			const size_t high) 
			pure @nogc @safe nothrow 
	{
		return DArraySlice!(typeof(this),T)(&this, cast(short)low, 
				cast(short)high
		);
	}

	pragma(inline, true)
	auto opSlice() pure @nogc @safe nothrow const {
		return DArraySlice!(typeof(this),const(T))
			(&this, cast(short)0, cast(short)this.length);
	}
	
	pragma(inline, true)
	auto opSlice(const size_t low, const size_t high) pure @nogc @safe nothrow const 
	{
		return DArraySlice!(typeof(this),const(T))
			(&this, cast(short)low, cast(short)high);
	}

	/// Gives the length of the array.
	pragma(inline, true)
	@property size_t length() const pure @nogc nothrow {
		return this.len;
	}
	
	/// Ditto
	pragma(inline, true)
	@property bool empty() const pure @nogc nothrow {
		return this.len == 0;
	}

}

version(unittest) {
	import std.stdio;
}

@safe unittest {
	DArray!(int) fsa;
	fsa.insertFront(1337);
	assert(fsa.length == 1);
	assert(fsa[0] == 1337);
	assert(fsa.front == 1337);
	assert(fsa.back == 1337);

	fsa.removeBack();
	assert(fsa.length == 0);
	assert(fsa.empty);
	fsa.insertFront(1336);

	assert(fsa.length == 1);
	assert(fsa[0] == 1336);
	assert(fsa.front == 1336);
	assert(fsa.back == 1336);
}

@safe unittest {
	DArray!(int) fsa;
	for(int i = 0; i < 32; ++i) {
		fsa.insertFront(i);
		assert(fsa.length == 1);
		assert(!fsa.empty);
		assert(fsa.front == i);
		assert(fsa.back == i);
		fsa.removeFront();
		assert(fsa.length == 0);
		assert(fsa.empty);
	}
}

@safe unittest {
	DArray!(int) fsa;
	for(int i = 0; i < 32; ++i) {
		fsa.insertFront(i);
		assert(fsa.length == 1);
		assert(!fsa.empty);
		assert(fsa.front == i);
		assert(fsa.back == i);
		fsa.removeBack();
		assert(fsa.length == 0);
		assert(fsa.empty);
	}
}

@safe unittest {
	DArray!(int) fsa;
	for(int i = 0; i < 32; ++i) {
		fsa.insertBack(i);
		assert(fsa.length == 1);
		assert(!fsa.empty);
		assert(fsa.front == i);
		assert(fsa.back == i);
		fsa.removeFront();
		assert(fsa.length == 0);
		assert(fsa.empty);
	}
}

///
@safe unittest {
	DArray!(int) fsa;
	fsa.insertBack(1337);
	assert(fsa.length == 1);
	assert(fsa[0] == 1337);

	fsa.insertBack(99, 5);

	foreach(it; fsa[1 .. fsa.length]) {
		assert(it == 99);
	}
}

@safe unittest {
	DArray!(int) fsa;
	fsa.insertBack(1337);
	assert(fsa.length == 1);
	assert(fsa[0] == 1337);
	
	fsa.removeBack();
	assert(fsa.length == 0);
	assert(fsa.empty);
}

@safe unittest {
	DArray!(int) fsa;
	fsa.insertBack(1337);
	fsa.insertBack(1338);
	assert(fsa.length == 2);
	assert(fsa[0] == 1337);
	assert(fsa[1] == 1338);
	
	fsa.removeAll();
	assert(fsa.length == 0);
	assert(fsa.empty);
}

unittest {
	DArray!(int) fsa;
	foreach(i; 0..10) {
		fsa.insertBack(i);
	}
	fsa.remove(1);
	foreach(idx, i; [0,2,3,4,5,6,7,8,9]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(0);
	foreach(idx, i; [2,3,4,5,6,7,8,9]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(7);
	foreach(idx, i; [2,3,4,5,6,7,8]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(5);
	foreach(idx, i; [2,3,4,5,6,8]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(1);
	foreach(idx, i; [2,4,5,6,8]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(0);
	foreach(idx, i; [4,5,6,8]) {
		assert(fsa[idx] == i);
	}
	fsa.remove(0);
	foreach(idx, i; [5,6,8]) {
		assert(fsa[idx] == i);
	}
}


///
@safe unittest {
	DArray!(int) fsa;
	assertEqual(fsa.capacity, 0);
	fsa.insertBack(1337);
	fsa.insertBack(1338);
	assert(fsa.capacity > 0);
	assert(fsa.length == 2);

	assert(fsa.front == 1337);
	assert(fsa.back == 1338);

	void f(ref const(DArray!int) d) {
		assert(d.front == 1337);
		assert(d.back == 1338);
	}

	f(fsa);
}


///
@safe unittest {
	DArray!(int) fsa;
	fsa.insertBack(1337);
	fsa.insertBack(1338);
	assert(fsa.length == 2);

	assert(fsa[0] == 1337);
	assert(fsa[1] == 1338);

	void f(ref const(DArray!int) d) {
		assert(d[0] == 1337);
		assert(d[1] == 1338);
	}

	f(fsa);
}
///
@safe unittest {
	DArray!(int) fsa;
	assert(fsa.empty);
	assert(fsa.length == 0);

	fsa.insertBack(1337);
	fsa.insertBack(1338);

	assert(fsa.length == 2);
	assert(!fsa.empty);
}

unittest {
	DArray!int d;
	assertEqual(d.length, 0);
	assert(d.empty);

	for(int i = 0; i < 20; ++i) {
		d.insertBack(i);
		assertEqual(d.length, i+1);
	}
	assertEqual(d.length, 20);

	DArray!int d2 = d;
	assertEqual(d.length, 20);
	assertEqual(d2.length, 20);

	d2.insertBack(21);
	assertEqual(d.length, 20);
	assertEqual(d2.length, 21);
}

unittest {
	import exceptionhandling;
	import std.stdio;

	DArray!(int) fsa;
	assert(fsa.empty);
	cast(void)assertEqual(fsa.length, 0);

	fsa.insertBack(1);
	assert(!fsa.empty);
	cast(void)assertEqual(fsa.length, 1);
	cast(void)assertEqual(fsa.front, 1);
	cast(void)assertEqual(fsa.back, 1);

	fsa.insertBack(2);
	assert(!fsa.empty);
	cast(void)assertEqual(fsa.length, 2);
	cast(void)assertEqual(fsa.front, 1);
	cast(void)assertEqual(fsa.back, 2);

	fsa.removeFront();
	assert(!fsa.empty);
	cast(void)assertEqual(fsa.length, 1);
	cast(void)assertEqual(fsa.front, 2);
	cast(void)assertEqual(fsa.back, 2);

	fsa.removeBack();
	//writefln("%s %s", fsa.begin, fsa.end);
	assert(fsa.empty);
	cast(void)assertEqual(fsa.length, 0);
}

unittest {
	import std.format;

	DArray!(char) fsa;
	formattedWrite(fsa[], "%s %s %s", "Hello", "World", 42);
	//assert(cast(string)fsa == "Hello World 42", cast(string)fsa);
}

unittest {
	import exceptionhandling;

	DArray!(int) fsa;
	auto a = [0,1,2,4,32,64,1024,2048,65000];
	foreach(idx, it; a) {
		fsa.insertBack(it);
		assertEqual(fsa.length, idx + 1);
		assertEqual(fsa.back, it);
		for(int i = 0; i < idx; ++i) {
			assertEqual(fsa[i], a[i]);
		}
	}
}

unittest {
	import exceptionhandling;
	import std.traits;
	import std.meta;
	import std.range;
	import std.stdio;
	import std.conv : to;
	foreach(Type; AliasSeq!(byte,int,long)) {
		DArray!(Type) fsa2;
		static assert(isInputRange!(typeof(fsa2[])));
		static assert(isForwardRange!(typeof(fsa2[])));
		static assert(isBidirectionalRange!(typeof(fsa2[])));
		foreach(idx, it; [[0], [0,1,2,3,4], [2,3,6,5,6,21,9,36,61,62]]) {
			DArray!(Type) fsa;
			foreach(jdx, jt; it) {
				fsa.insertBack(to!Type(jt));
				//writefln("%s idx %d jdx %d length %d", Type.stringof, idx, jdx, fsa.length);
				cast(void)assertEqual(fsa.length, jdx + 1);
				foreach(kdx, kt; it[0 .. jdx]) {
					assertEqual(fsa[kdx], kt);
				}

				{
					auto forward = fsa[];
					auto forward2 = forward;
					cast(void)assertEqual(forward.length, jdx + 1);
					for(size_t i = 0; i < forward.length; ++i) {
						cast(void)assertEqual(forward[i], it[i]);
						cast(void)assertEqual(forward2.front, it[i]);
						forward2.popFront();
					}
					assert(forward2.empty);

					auto backward = fsa[];
					auto backward2 = backward.save;
					cast(void)assertEqual(backward.length, jdx + 1);
					for(size_t i = 0; i < backward.length; ++i) {
						cast(void)assertEqual(backward[backward.length - i - 1],
								it[jdx - i]
						);

						cast(void)assertEqual(backward2.back, 
								it[0 .. jdx + 1 - i].back
						);
						backward2.popBack();
					}
					assert(backward2.empty);
					auto forward3 = fsa[].save;
					auto forward4 = fsa[0 .. jdx + 1];

					while(!forward3.empty && !forward4.empty) {
						cast(void)assertEqual(forward3.front, forward4.front);
						cast(void)assertEqual(forward3.back, forward4.back);
						forward3.popFront();
						forward4.popFront();
					}
					assert(forward3.empty);
					assert(forward4.empty);
				}

				{
					const(DArray!(Type))* constFsa;
					constFsa = &fsa;
					auto forward = (*constFsa)[];
					auto forward2 = forward.save;
					cast(void)assertEqual(forward.length, jdx + 1);
					for(size_t i = 0; i < forward.length; ++i) {
						cast(void)assertEqual(cast(int)forward[i], it[i]);
						cast(void)assertEqual(cast(int)forward2.front, it[i]);
						forward2.popFront();
					}
					assert(forward2.empty);

					auto backward = (*constFsa)[];
					auto backward2 = backward.save;
					cast(void)assertEqual(backward.length, jdx + 1);
					for(size_t i = 0; i < backward.length; ++i) {
						cast(void)assertEqual(backward[backward.length - i - 1],
								it[jdx - i]
						);

						cast(void)assertEqual(backward2.back, 
								it[0 .. jdx + 1 - i].back
						);
						backward2.popBack();
					}
					assert(backward2.empty);
					auto forward3 = (*constFsa)[];
					auto forward4 = (*constFsa)[0 .. jdx + 1];

					while(!forward3.empty && !forward4.empty) {
						cast(void)assertEqual(forward3.front, forward4.front);
						cast(void)assertEqual(forward3.back, forward4.back);
						forward3.popFront();
						forward4.popFront();
					}
					assert(forward3.empty);
					assert(forward4.empty);
				}
			}
		}
	}
}

// Test case Issue #2
unittest {
	import exceptionhandling;

	DArray!(int) fsa;
	fsa.insertBack(0);
	assert(fsa.length == 1);
	fsa.insertBack(1);

	assertEqual(fsa[0], 0);	
	assertEqual(fsa[1], 1);	
	assertEqual(fsa.front, 0);
	assertEqual(fsa.back, 1);
}

unittest {
	import std.stdio;
	import core.memory;
	enum size = 128;
	DArray!(int)[size] arrays;
	foreach (i; 0..size) {
	    foreach (j; 0..size) {
			assert(arrays[i].length == j);
	        arrays[i].insertBack(i * 1000 + j);
	    }
	}
	bool[int] o;
	foreach (i; 0..size) {
	    foreach (j; 0..size) {
			assert(arrays[i][j] !in o);
	        o[arrays[i][j]] = true;
	    }
	}
	assert(size * size == o.length);
}

// issue #1 won't fix not sure why
unittest {
	import std.stdio;
	import core.memory;
	enum size = 256;
	DArray!(Object) arrays;
	foreach (i; 0..size) {
		auto o = new Object();
		assert(arrays.length == i);
		foreach(it; arrays[]) {
			assert(it !is null);
			assert(it.toHash());
		}
	    arrays.insertBack(o);
		assert(arrays.back is o);
		assert(!arrays.empty);
		assert(arrays.length == i + 1);
	}

	assert(arrays.length == size);
	for(int i = 0; i < size; ++i) {
		assert(arrays[i] !is null);
		assert(arrays[i].toHash());
	}
	bool[Object] o;
	foreach (i; 0..size) {
		assert(arrays[i] !is null);
		assert(arrays[i] !in o);
	    o[arrays[i]] = true;
	    
	}
	assert(size == o.length);
}

unittest {
	import exceptionhandling;
	DArray!(int) fsa;
	fsa.insertFront(1337);
	assert(!fsa.empty);
	assertEqual(fsa.length, 1);
	assertEqual(fsa.back, 1337);
	assertEqual(fsa.front, 1337);
}

// Test case Issue #2
unittest {
	enum size = 256;
	DArray!(Object)[size] arrays;
	foreach (i; 0..size) {
	    foreach (j; 0..size) {
	        arrays[i].insertBack(new Object);
	    }
	}
	bool[Object] o;
	foreach (i; 0..size) {
	    foreach (j; 0..size) {
	        o[arrays[i][j]] = true;
	    }
	}
	assert(o.length == size * size);
}

unittest {
	import std.range.primitives : hasAssignableElements, hasSlicing, isRandomAccessRange;
	DArray!(int) fsa;
	auto s = fsa[];
	static assert(hasSlicing!(typeof(s)));
	static assert(isRandomAccessRange!(typeof(s)));
	static assert(hasAssignableElements!(typeof(s)));
}

unittest {
	import exceptionhandling;

	DArray!(int) fsa;
	for(int i = 0; i < 32; ++i) {
		fsa.insertBack(i);	
	}

	auto s = fsa[];
	for(int i = 0; i < 32; ++i) {
		assert(s[i] == i);
	}
	s = s[0 .. 33];
	for(int i = 0; i < 32; ++i) {
		assert(s[i] == i);
	}

	auto t = s.save;
	s.popFront();
	for(int i = 0; i < 32; ++i) {
		assert(t[i] == i);
	}

	auto r = t[10, 20];
	for(int i = 10; i < 20; ++i) {
		assertEqual(r[i-10], fsa[i]);
	}

	foreach(ref it; r) {
		it = 0;
	}

	for(int i = 10; i < 20; ++i) {
		assertEqual(r[i-10], 0);
	}
}

unittest {
	DArray!(int) fsaM;
	for(int i = 0; i < 32; ++i) {
		fsaM.insertBack(i);	
	}

	const(DArray!(int)) fsa = fsaM;

	auto s = fsa[];
	for(int i = 0; i < 32; ++i) {
		assert(s[i] == i);
	}
	s = s[0 .. 33];
	for(int i = 0; i < 32; ++i) {
		assert(s[i] == i);
	}

	auto t = s.save;
	s.popFront();
	for(int i = 0; i < 32; ++i) {
		assert(t[i] == i);
	}
}

unittest {
	import std.random : Random, uniform;
	import std.format : format;
	struct Data {
		ulong a, b, c, d, e;
	}

	auto rnd = Random(1337);
	DArray!(Data) a;
	for(size_t i = 0; i < 4096; ++i) {
		Data d;
		d.a = i;
		d.b = i;
		d.c = i;
		d.d = i;
		d.e = i;

		a.insertBack(d);

		int c = uniform(4,10, rnd);
		while(a.length > c) {
			a.removeFront();
		}
		assert(!a.empty);
		assert(a.length <= c, format("%d < %d", a.length, c));

		auto r = a[];
		assert(r.back.a == i);
		assert(r.front.a <= i);

		foreach(it; r[]) {
			assert(it.a <= i);
		}

		auto cr = (*(cast(const(typeof(a))*)(&a)));
		assert(cr.back.a == i);
		assert(cr.front.a <= i);

		auto crr = cr[];
		assert(crr.front.a <= i);
		assert(crr.back.a <= i);
		foreach(it; crr.save) {
			assert(it.a <= i);
		}
	}
}
