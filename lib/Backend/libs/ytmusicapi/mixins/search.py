from typing import Any, Dict, List, Optional, Union

from ytmusicapi.continuations import get_continuations
from ytmusicapi.mixins._protocol import MixinProtocol
from ytmusicapi.parsers.search import *


class SearchMixin(MixinProtocol):
    def search(
        self,
        query: str,
        filter: Optional[str] = None,
        scope: Optional[str] = None,
        limit: int = 20,
        ignore_spelling: bool = False,
    ) -> List[Dict]:
        body = {"query": query}
        endpoint = "search"
        search_results: List[Dict[str, Any]] = []
        filters = [
            "albums",
            "artists",
            "playlists",
            "community_playlists",
            "featured_playlists",
            "songs",
            "videos",
            "profiles",
            "podcasts",
            "episodes",
        ]
        if filter and filter not in filters:
            raise Exception(
                "Invalid filter provided. Please use one of the following filters or leave out the parameter: "
                + ", ".join(filters)
            )

        scopes = ["library", "uploads"]
        if scope and scope not in scopes:
            raise Exception(
                "Invalid scope provided. Please use one of the following scopes or leave out the parameter: "
                + ", ".join(scopes)
            )

        if scope == scopes[1] and filter:
            raise Exception(
                "No filter can be set when searching uploads. Please unset the filter parameter when scope is set to "
                "uploads. "
            )

        if scope == scopes[0] and filter in filters[3:5]:
            raise Exception(
                f"{filter} cannot be set when searching library. "
                f"Please use one of the following filters or leave out the parameter: "
                + ", ".join(filters[0:3] + filters[5:])
            )

        params = get_search_params(filter, scope, ignore_spelling)
        if params:
            body["params"] = params

        response = self._send_request(endpoint, body)

        # no results
        if "contents" not in response:
            return search_results

        if "tabbedSearchResultsRenderer" in response["contents"]:
            tab_index = 0 if not scope or filter else scopes.index(scope) + 1
            results = response["contents"]["tabbedSearchResultsRenderer"]["tabs"][tab_index]["tabRenderer"][
                "content"
            ]
        else:
            results = response["contents"]

        results = nav(results, SECTION_LIST)

        # no results
        if len(results) == 1 and "itemSectionRenderer" in results:
            return search_results

        # set filter for parser
        if filter and "playlists" in filter:
            filter = "playlists"
        elif scope == scopes[1]:
            filter = scopes[1]

        for res in results:
            if "musicCardShelfRenderer" in res:
                top_result = parse_top_result(
                    res["musicCardShelfRenderer"], self.parser.get_search_result_types()
                )
                search_results.append(top_result)
                if results := nav(res, ["musicCardShelfRenderer", "contents"], True):
                    category = None
                    # category "more from youtube" is missing sometimes
                    if "messageRenderer" in results[0]:
                        category = nav(results.pop(0), ["messageRenderer", *TEXT_RUN_TEXT])
                    type = None
                else:
                    continue

            elif "musicShelfRenderer" in res:
                results = res["musicShelfRenderer"]["contents"]
                type_filter = filter
                category = nav(res, MUSIC_SHELF + TITLE_TEXT, True)
                if not type_filter and scope == scopes[0]:
                    type_filter = category

                type = type_filter[:-1].lower() if type_filter else None

            else:
                continue

            search_result_types = self.parser.get_search_result_types()
            search_results.extend(parse_search_results(results, search_result_types, type, category))

            if filter:  # if filter is set, there are continuations

                def request_func(additionalParams):
                    return self._send_request(endpoint, body, additionalParams)

                def parse_func(contents):
                    return parse_search_results(contents, search_result_types, type, category)

                search_results.extend(
                    get_continuations(
                        res["musicShelfRenderer"],
                        "musicShelfContinuation",
                        limit - len(search_results),
                        request_func,
                        parse_func,
                    )
                )

        return search_results

    def get_search_suggestions(self, query: str, detailed_runs=False) -> Union[List[str], List[Dict]]:
        """
        Get Search Suggestions

        :param query: Query string, i.e. 'faded'
        :param detailed_runs: Whether to return detailed runs of each suggestion.
            If True, it returns the query that the user typed and the remaining
            suggestion along with the complete text (like many search services
            usually bold the text typed by the user).
            Default: False, returns the list of search suggestions in plain text.
        :return: List of search suggestion results depending on ``detailed_runs`` param.

          Example response when ``query`` is 'fade' and ``detailed_runs`` is set to ``False``::

              [
                "faded",
                "faded alan walker lyrics",
                "faded alan walker",
                "faded remix",
                "faded song",
                "faded lyrics",
                "faded instrumental"
              ]

          Example response when ``detailed_runs`` is set to ``True``::

              [
                {
                  "text": "faded",
                  "runs": [
                    {
                      "text": "fade",
                      "bold": true
                    },
                    {
                      "text": "d"
                    }
                  ]
                },
                {
                  "text": "faded alan walker lyrics",
                  "runs": [
                    {
                      "text": "fade",
                      "bold": true
                    },
                    {
                      "text": "d alan walker lyrics"
                    }
                  ]
                },
                {
                  "text": "faded alan walker",
                  "runs": [
                    {
                      "text": "fade",
                      "bold": true
                    },
                    {
                      "text": "d alan walker"
                    }
                  ]
                },
                ...
              ]
        """

        body = {"input": query}
        endpoint = "music/get_search_suggestions"

        response = self._send_request(endpoint, body)
        search_suggestions = parse_search_suggestions(response, detailed_runs)

        return search_suggestions
