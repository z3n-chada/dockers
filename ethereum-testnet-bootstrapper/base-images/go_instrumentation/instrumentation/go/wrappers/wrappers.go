package wrappers

/*
	The command line must specify a library path (using CGO_LDFLAGS). CGO_CFLAGS
	need not be set, since the Antithesis instrumentation functions are declared
	inline, below. In the unlikely event that any of these changes, this file
	must also be changed. Inlining these declarations has proven to be less brittle
	than imposing a compile-time requirement on "instrumentation.h".

	Flags for CGO are collected, so the blank declarations have no effect.
	However, they can be modified in build scripts to be built into customer code.

	The C headers define the various integer types, as well as the free() function.
	The dependency on -lstdc++ is mysterious to us, but necessary.
*/

// #cgo LDFLAGS: -lpthread -ldl -lc -lm -lvoidstar
// #cgo CFLAGS:
// #include <stdlib.h>
// #include <stdbool.h>
// int fuzz_getchar();
// void fuzz_info_message( const char* message );
// void fuzz_error_message( const char* message );
// void ext_cov_trace_pc_guard_init(size_t edge_count, const char* symbol_file_name);
// void ext_cov_trace_pc_guard(size_t edge);
// size_t init_coverage_module(size_t edge_count, const char* symbol_file_name);
// bool notify_coverage(size_t edge_plus_module);
// void fuzz_exit(int exit_code);
import "C"

import (
	"fmt"
	"os"
	"unsafe"
)

var everInit = false

// CoverSize is the maximum number of edges.
// TODO Parameterize this from the instrumentor.
const CoverSize = 64 << 14

// InstrumentationSymbolTableName is the default name of the file
// describing edges found during instrumentation, uploaded to S3.
const InstrumentationSymbolTableName string = "symbols.sym.tsv"

// AntithesisGoInstrumentationVerbose points to the literal
// "ANT_GO_INSTRUMENTATION_VERBOSE". This environment variable
// should be present if you want every edge reported.
const AntithesisGoInstrumentationVerbose string = "ANT_GO_INSTRUMENTATION_VERBOSE"

var edgesVisited = map[uint32]bool{}

func getInstrumentationWrapperVerbose() bool {
	_, present := os.LookupEnv(AntithesisGoInstrumentationVerbose)
	return present
}

// InstrumentationWrapperVerbose reads environment variables specific
// to the Go instrumentation. Right now, this simply causes edge numbers
// to be written to stderr.
var instrumentationWrapperVerbose bool = getInstrumentationWrapperVerbose()

// Initialize can be called directory from a test harness (TODO).
func Initialize() {
	executable, _ := os.Executable()
	InfoMessage(fmt.Sprintf("Initializing instrumented Go program %s from %s with %d edges", executable, InstrumentationSymbolTableName, CoverSize))

	// Until the name of the symbol table is configurable, this can remain
	// a private method.
	s := C.CString(InstrumentationSymbolTableName)
	C.ext_cov_trace_pc_guard_init(C.ulong(CoverSize), s)
	C.free(unsafe.Pointer(s))
	everInit = true
}

// Callback will be inserted into the instrumentation.
func Callback(edge uint32) {
	if !everInit {
		Initialize()
	}
	C.ext_cov_trace_pc_guard(C.ulong(edge))
	if instrumentationWrapperVerbose {
		if _, seen := edgesVisited[edge]; !seen {
			edgesVisited[edge] = true
			fmt.Fprintf(os.Stderr, "Visited edge %d\n", edge)
		}
	}
}

// FuzzGetChar is for the use of the test harness.
func FuzzGetChar() byte {
	return (byte)(C.fuzz_getchar())
}

// FuzzExit is inserted by the instrumentation.
func FuzzExit(exit int) {
	C.fuzz_exit(C.int(exit))
}

// InfoMessage is for the use of the test harness.
func InfoMessage(message string) {
	s := C.CString(message)
	C.fuzz_info_message(s)
	C.free(unsafe.Pointer(s))
}

// ErrorMessage is for the use of the test harness.
func ErrorMessage(message string) {
	s := C.CString(message)
	C.fuzz_error_message(s)
	C.free(unsafe.Pointer(s))
}
