#include "tree_sitter/api.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

typedef struct Node {
  TSNode node;
  const char *type;
  TSSymbol symbol;
  TSPoint endPoint;
  uint32_t endByte;
  uint32_t childCount;
  const char *fieldName;
  bool     isNamed;
  bool     isExtra;
  bool     isMissing;
} Node;

void log_to_stdout(void *payload, TSLogType type, const char *message) {
  printf("%s\n", message);
}

void ts_parser_log_to_stderr(TSParser *parser) {
  ts_parser_set_logger(parser, (TSLogger) {.log = log_to_stdout, .payload = NULL});
}

static inline void ts_node_poke(const char *fieldName, TSNode node, Node *out) {
  out->node = node;
  out->symbol = ts_node_symbol(node);
  out->type = ts_node_type(node);
  out->endPoint = ts_node_end_point(node);
  out->endByte = ts_node_end_byte(node);
  out->childCount = ts_node_child_count(node);
  out->fieldName = fieldName;
  out->isNamed = ts_node_is_named(node);
  out->isExtra = ts_node_is_extra(node);
  out->isMissing = ts_node_is_missing(node);
}

void ts_node_poke_p(TSNode *node, Node *out) {
  assert(node != NULL);
  ts_node_poke(NULL, *node, out);
}

void ts_tree_root_node_p(TSTree *tree, Node *outNode) {
  assert(tree != NULL);
  assert(outNode != NULL);
  TSNode root = ts_tree_root_node(tree);
  assert(root.id != NULL);
  ts_node_poke(NULL, root, outNode);
}

void ts_node_copy_child_nodes(const TSNode *parentNode, Node *outChildNodes) {
  assert(parentNode != NULL);
  assert(outChildNodes != NULL);
  TSTreeCursor curse = ts_tree_cursor_new(*parentNode);

  if (ts_tree_cursor_goto_first_child(&curse)) {
    do {
      TSNode current = ts_tree_cursor_current_node(&curse);
      ts_node_poke(ts_tree_cursor_current_field_name(&curse), current, outChildNodes);
      outChildNodes++;
    } while (ts_tree_cursor_goto_next_sibling(&curse));
  }

  ts_tree_cursor_delete(&curse);
}

size_t sizeof_tsnode() {
  return sizeof(TSNode);
}

size_t sizeof_tspoint() {
  return sizeof(TSPoint);
}

size_t sizeof_node() {
  return sizeof(Node);
}

size_t sizeof_tstreecursor() {
  return sizeof(TSTreeCursor);
}

void ts_tree_cursor_new_p(TSNode *node, TSTreeCursor *outCursor) {
  assert(node != NULL);
  assert(outCursor != NULL);
  *outCursor = ts_tree_cursor_new(*node);
}

void ts_tree_cursor_reset_p(TSTreeCursor *cursor, TSNode *node) {
  assert(cursor != NULL);
  assert(node != NULL);
  ts_tree_cursor_reset(cursor, *node);
}

bool ts_tree_cursor_current_node_p(const TSTreeCursor *cursor, Node *outNode) {
  assert(cursor != NULL);
  assert(outNode != NULL);
  TSNode tsNode = ts_tree_cursor_current_node(cursor);
  if (!ts_node_is_null(tsNode)) {
    ts_node_poke(ts_tree_cursor_current_field_name(cursor), tsNode, outNode);
  }
  return false;
}

uint32_t ts_tree_cursor_copy_child_nodes(TSTreeCursor *cursor, Node *outChildNodes) {
  assert(cursor != NULL);
  assert(outChildNodes != NULL);
  uint32_t count = 0;

  if (ts_tree_cursor_goto_first_child(cursor)) {
    do {
      TSNode current = ts_tree_cursor_current_node(cursor);
      const char *fieldName = ts_tree_cursor_current_field_name(cursor);
      if (fieldName || (ts_node_is_named(current) && !ts_node_is_extra(current))) {
        ts_node_poke(fieldName, current, outChildNodes);
        count++;
        outChildNodes++;
      }
    } while (ts_tree_cursor_goto_next_sibling(cursor));
    ts_tree_cursor_goto_parent(cursor);
  }
  return count;
}

char *ts_node_string_p(TSNode *self) {
  assert(self != NULL);
  return ts_node_string(*self);
}

TSQuery *ts_query_new_p(const TSLanguage *language, const char *source, uint32_t length) {
  uint32_t error_offset;
  TSQueryError error_type;
  TSQuery *query = ts_query_new(language, source, length, &error_offset, &error_type);
  return query;
}

void ts_query_delete_p(TSQuery *query) {
  assert(query != NULL);
  ts_query_delete(query);
}

TSQueryCursor *ts_query_cursor_new_p(void)
{
  return ts_query_cursor_new();
}

void ts_query_cursor_delete_p(TSQueryCursor *cursor)
{
  assert(cursor != NULL);
  ts_query_cursor_delete(cursor);
}

void ts_query_cursor_exec_p(TSQueryCursor *cursor, const TSQuery *query, TSNode *node)
{
  assert(node != NULL);
  ts_query_cursor_exec(cursor, query, *node);
}

#define INITIAL_NODE_CAPACITY 128
Node *ts_query_matches_to_nodes(TSTree *tree, TSQuery *query, size_t *outCount) {
  assert(tree != NULL);
  assert(query != NULL);
  assert(outCount != NULL);

  TSNode root = ts_tree_root_node(tree);

  TSQueryCursor *cursor = ts_query_cursor_new();
  ts_query_cursor_exec(cursor, query, root);

  size_t capacity = INITIAL_NODE_CAPACITY;
  Node *nodes = malloc(capacity * sizeof(Node));
  if (!nodes) {
    perror("Failed to allocate memory for nodes");
    ts_query_cursor_delete(cursor);
    return NULL;
  }

  size_t count = 0;

  TSQueryMatch match;
  while (ts_query_cursor_next_match(cursor, &match)) {
    for (uint32_t i = 0; i < match.capture_count; i++) {
      TSQueryCapture capture = match.captures[i];
      TSNode capturedNode = capture.node;

      if (count >= capacity) {
        capacity *= 2;
        Node *newNodes = realloc(nodes, capacity * sizeof(Node));
        if (!newNodes) {
          perror("Failed to reallocate memory for nodes");
          free(nodes);
          ts_query_cursor_delete(cursor);
          return NULL;
        }
        nodes = newNodes;
      }

      ts_node_poke(NULL, capturedNode, nodes + count);
      count++;
    }
  }

  *outCount = count;
  ts_query_cursor_delete(cursor);

  return nodes;
}
