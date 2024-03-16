#define DUCKDB_EXTENSION_MAIN

#include "duckdb.hpp"
#include "duckdb/common/exception.hpp"
#include "duckdb/common/string_util.hpp"
#include "duckdb/function/scalar_function.hpp"
#include "duckdb/main/extension_util.hpp"
#include <duckdb/parser/parsed_data/create_scalar_function_info.hpp>

namespace duckdb {
inline void QuackScalarFun(DataChunk &args, ExpressionState &state, Vector &result) {
  auto &name_vector = args.data[0];
  UnaryExecutor::Execute<string_t, string_t>(name_vector, result, args.size(), [&](string_t name) {
    return StringVector::AddString(result, "Quack " + name.GetString() + " 🐥");
  });
}

static void LoadInternal(DatabaseInstance &instance) {
  // Register a scalar function
  auto quack_scalar_function =
      ScalarFunction("quack", {LogicalType::VARCHAR}, LogicalType::VARCHAR, QuackScalarFun);
  ExtensionUtil::RegisterFunction(instance, quack_scalar_function);
}

class QuackExtension : public Extension {
public:
  void Load(DuckDB &db) override;
  std::string Name() override;
};

void duckdb::QuackExtension::Load(duckdb::DuckDB &db) { LoadInternal(*db.instance); }

std::string duckdb::QuackExtension::Name() { return "quack"; }
} // namespace duckdb

//
// We will call these extern functions via the C ABI from Zig.
//

// DuckDB requires the version returned from the extension to match the version
// calling it. Here we use the linked version reported by `libduckdb`.
extern "C" char const *extension_version(void) { return duckdb::DuckDB::LibraryVersion(); }

// This function is responsible for bootstrapping the extension into the DuckDB
// internals. The `quack` extension is trivial and only registers a single scalar
// function.
extern "C" void extension_init(duckdb::DatabaseInstance &db) {
  duckdb::DuckDB db_wrapper(db);
  db_wrapper.LoadExtension<duckdb::QuackExtension>();
}

#ifndef DUCKDB_EXTENSION_MAIN
#error DUCKDB_EXTENSION_MAIN not defined
#endif
