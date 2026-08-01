package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

var TYPES = []string{"WOOD", "FIRE", "EARTH", "METAL", "WATER", "YANG", "YIN"}

const (
	charactersGlob = "resources/characters/*.tres"
	movesGlob = "resources/moves/*.tres"
)

var (
	reMoves = regexp.MustCompile(`"([^"]+)"`)
)

type Stats struct {
	HP int
	Attack int
	Defense int
	Speed int
	Intelligence int
	Spirit int
}

type Row struct {
	ID string
	Name string
	Type int
	Secondary int // -1 = なし
	Stats Stats
	Moves []string
}

func getValue(text, key string) (string, bool) {
	// Python: rf"^{key} = ([^\n]+)" MULTILINE
	pat := regexp.MustCompile(`(?m)^` + regexp.QuoteMeta(key) + ` = ([^\n]+)`)
	m := pat.FindStringSubmatch(text)
	if m == nil {
		return "", false
	}
	v := strings.TrimSpace(m[1])
	v = strings.Trim(v, `"`) // Pythonの.strip().strip('"') 相当
	return v, true
}

func parseIntOr(s string, def int) int {
	if s == "" {
		return def
	}
	i, err := strconv.Atoi(s)
	if err!= nil {
		return def
	}
	return i
}

func parseCharacters(charGlob string) ([]Row, error) {
	paths, err := filepath.Glob(charGlob)
	if err!= nil {
		return nil, err
	}
	sort.Strings(paths)

	var rows []Row
	for _, p := range paths {
		b, err := os.ReadFile(p)
		if err!= nil {
			continue
		}
		text := string(b)

		id, ok := getValue(text, "id")
		if!ok {
			continue
		}

		secondary := -1
		if v, ok := getValue(text, "secondary_type"); ok {
			secondary = parseIntOr(v, -1)
		}

		name, _ := getValue(text, "name")
		typeStr, _ := getValue(text, "type")

		stats := Stats{
			HP: parseIntOr(mustGet(text, "hp"), 0),
			Attack: parseIntOr(mustGet(text, "attack"), 0),
			Defense: parseIntOr(mustGet(text, "defense"), 0),
			Speed: parseIntOr(mustGet(text, "speed"), 0),
			Intelligence: parseIntOr(mustGet(text, "intelligence"), 0),
			Spirit: parseIntOr(mustGet(text, "spirit"), 0),
		}

		movesRaw, _ := getValue(text, "moves")
		var moves []string
		if movesRaw!= "" {
			for _, mm := range reMoves.FindAllStringSubmatch(movesRaw, -1) {
				moves = append(moves, mm[1])
			}
		}

		rows = append(rows, Row{
			ID: id,
			Name: name,
			Type: parseIntOr(typeStr, 0),
			Secondary: secondary,
			Stats: stats,
			Moves: moves,
		})
	}
	return rows, nil
}

func mustGet(text, key string) string {
	v, _ := getValue(text, key)
	return v
}

func parseMoves(moveGlob string) (map[string]int, error) {
	paths, _ := filepath.Glob(moveGlob)
	mp := make(map[string]int)
	for _, p := range paths {
		b, err := os.ReadFile(p)
		if err!= nil {
			continue
		}
		text := string(b)
		id, ok := getValue(text, "id")
		if!ok {
			continue
		}
		powerStr, ok := getValue(text, "power")
		if!ok {
			continue
		}
		mp[id] = parseIntOr(powerStr, 0)
	}
	return mp, nil
}

func typeLabel(primary, secondary int) string {
	label := "?"
	if primary >= 0 && primary < len(TYPES) {
		label = TYPES[primary]
	}
	if secondary >= 0 && secondary < len(TYPES) {
		label += "+" + TYPES[secondary]
	}
	return label
}

func statSum(r Row) int {
	s := r.Stats
	return s.HP + s.Attack + s.Defense + s.Speed + s.Intelligence + s.Spirit
}

func printTable(rows []Row, movePower map[string]int, showMoves bool) {
	header := fmt.Sprintf("%-18s %-6s %-12s %4s %3s %3s %3s %3s %3s %3s",
		"id", "name", "type", "sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR")
	if showMoves {
		header += " moves"
	}
	fmt.Println(header)
	fmt.Println(strings.Repeat("-", len(header)))

	for _, r := range rows {
		line := fmt.Sprintf("%-18s %-6s %-12s %4d %3d %3d %3d %3d %3d %3d",
			r.ID, r.Name, typeLabel(r.Type, r.Secondary), statSum(r),
			r.Stats.HP, r.Stats.Attack, r.Stats.Defense,
			r.Stats.Speed, r.Stats.Intelligence, r.Stats.Spirit)
		if showMoves {
			var parts []string
			for _, m := range r.Moves {
				if movePower!= nil {
					if p, ok := movePower[m]; ok {
						parts = append(parts, fmt.Sprintf("%s(%d)", m, p))
					} else {
						parts = append(parts, fmt.Sprintf("%s(?)", m))
					}
				} else {
					parts = append(parts, m)
				}
			}
			line += " " + strings.Join(parts, ", ")
		}
		fmt.Println(line)
	}
}

func printTypeDistribution(rows []Row) {
	primary := make([]int, len(TYPES))
	secondary := make([]int, len(TYPES))
	for _, r := range rows {
		if r.Type >= 0 && r.Type < len(TYPES) {
			primary[r.Type]++
		}
		if r.Secondary >= 0 && r.Secondary < len(TYPES) {
			secondary[r.Secondary]++
		}
	}
	fmt.Println("=== Type distribution (primary / with secondary) ===")
	for i, t := range TYPES {
		fmt.Printf(" %-6s %2d / %2d\n", t, primary[i], secondary[i])
	}
}

func writeCSV(rows []Row) error {
	w := csv.NewWriter(os.Stdout)
	defer w.Flush()
	header := []string{"id", "name", "type", "secondary_type", "hp", "attack", "defense", "speed", "intelligence", "spirit", "moves"}
	if err := w.Write(header); err!= nil {
		return err
	}
	for _, r := range rows {
		rec := []string{
			r.ID,
			r.Name,
			strconv.Itoa(r.Type),
			strconv.Itoa(r.Secondary),
			strconv.Itoa(r.Stats.HP),
			strconv.Itoa(r.Stats.Attack),
			strconv.Itoa(r.Stats.Defense),
			strconv.Itoa(r.Stats.Speed),
			strconv.Itoa(r.Stats.Intelligence),
			strconv.Itoa(r.Stats.Spirit),
			strings.Join(r.Moves, ","),
		}
		if err := w.Write(rec); err!= nil {
			return err
		}
	}
	return nil
}

func main() {
	sortKey := flag.String("sort", "", "Sort by 'sum' (or '-sum' for descending), 'id', or 'name'")
	typesOnly := flag.Bool("types-only", false, "Print only the type distribution")
	showMoves := flag.Bool("moves", false, "Show each character's moves (with move power)")
	csvOut := flag.Bool("csv", false, "Output as CSV to stdout")
	flag.Parse()

	rows, err := parseCharacters(charactersGlob)
	if err!= nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// sort
	if *sortKey!= "" {
		key := *sortKey
		reverse := false
		if strings.HasPrefix(key, "-") {
			key = strings.TrimPrefix(key, "-")
			reverse = true
		}
		switch key {
		case "sum":
			sort.Slice(rows, func(i, j int) bool {
				if reverse {
					return statSum(rows[i]) > statSum(rows[j])
				}
				return statSum(rows[i]) < statSum(rows[j])
			})
		case "id":
			sort.Slice(rows, func(i, j int) bool {
				if reverse {
					return rows[i].ID > rows[j].ID
				}
				return rows[i].ID < rows[j].ID
			})
		case "name":
			sort.Slice(rows, func(i, j int) bool {
				if reverse {
					return rows[i].Name > rows[j].Name
				}
				return rows[i].Name < rows[j].Name
			})
		default:
			fmt.Fprintf(os.Stderr, "Unknown sort key: %s\n", key)
			os.Exit(2)
		}
	} else {
		sort.Slice(rows, func(i, j int) bool { return rows[i].ID < rows[j].ID })
	}

	if *csvOut {
		if err := writeCSV(rows); err!= nil {
			os.Exit(1)
		}
		return
	}

	if *typesOnly {
		printTypeDistribution(rows)
		fmt.Printf("\nTotal: %d characters\n", len(rows))
		return
	}

	var movePower map[string]int
	if *showMoves {
		movePower, _ = parseMoves(movesGlob)
	}

	printTable(rows, movePower, *showMoves)
	fmt.Println()
	printTypeDistribution(rows)
	fmt.Printf("\nTotal: %d characters\n", len(rows))
}
