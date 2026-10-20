/// Client repository contract.
library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class ClientRepository
    implements Repository<Client, ClientId> {
  Future<Client?> getByName(String name);

  Future<bool> existsByName(String name);
}
