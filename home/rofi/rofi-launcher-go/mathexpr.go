package main

import (
	"fmt"
	"math"
	"strconv"
	"strings"
)

// evalMathExpr evaluates a simple arithmetic expression containing only
// + - * / % ( ) digits and whitespace, mirroring the sanitized eval() call
// in launcher.py's main loop (which only ever invokes Python's eval() after
// checking the input is built solely from that character set).
func evalMathExpr(expr string) (float64, error) {
	p := &mathParser{input: []rune(expr), pos: 0}
	p.skipSpace()
	if p.pos >= len(p.input) {
		return 0, fmt.Errorf("empty expression")
	}
	val, err := p.parseExpr()
	if err != nil {
		return 0, err
	}
	p.skipSpace()
	if p.pos != len(p.input) {
		return 0, fmt.Errorf("unexpected trailing input")
	}
	return val, nil
}

type mathParser struct {
	input []rune
	pos   int
}

func (p *mathParser) skipSpace() {
	for p.pos < len(p.input) && p.input[p.pos] == ' ' {
		p.pos++
	}
}

func (p *mathParser) peek() rune {
	if p.pos >= len(p.input) {
		return 0
	}
	return p.input[p.pos]
}

// parseExpr handles + and - (lowest precedence).
func (p *mathParser) parseExpr() (float64, error) {
	val, err := p.parseTerm()
	if err != nil {
		return 0, err
	}
	for {
		p.skipSpace()
		switch p.peek() {
		case '+':
			p.pos++
			rhs, err := p.parseTerm()
			if err != nil {
				return 0, err
			}
			val += rhs
		case '-':
			p.pos++
			rhs, err := p.parseTerm()
			if err != nil {
				return 0, err
			}
			val -= rhs
		default:
			return val, nil
		}
	}
}

// parseTerm handles * / % (higher precedence than + -).
func (p *mathParser) parseTerm() (float64, error) {
	val, err := p.parseUnary()
	if err != nil {
		return 0, err
	}
	for {
		p.skipSpace()
		switch p.peek() {
		case '*':
			p.pos++
			rhs, err := p.parseUnary()
			if err != nil {
				return 0, err
			}
			val *= rhs
		case '/':
			p.pos++
			rhs, err := p.parseUnary()
			if err != nil {
				return 0, err
			}
			if rhs == 0 {
				return 0, fmt.Errorf("division by zero")
			}
			val /= rhs
		case '%':
			p.pos++
			rhs, err := p.parseUnary()
			if err != nil {
				return 0, err
			}
			if rhs == 0 {
				return 0, fmt.Errorf("division by zero")
			}
			val = math.Mod(val, rhs)
		default:
			return val, nil
		}
	}
}

// parseUnary handles unary +/-.
func (p *mathParser) parseUnary() (float64, error) {
	p.skipSpace()
	switch p.peek() {
	case '-':
		p.pos++
		val, err := p.parseUnary()
		return -val, err
	case '+':
		p.pos++
		return p.parseUnary()
	default:
		return p.parseAtom()
	}
}

// parseAtom handles parenthesized expressions and numeric literals.
func (p *mathParser) parseAtom() (float64, error) {
	p.skipSpace()
	if p.peek() == '(' {
		p.pos++
		val, err := p.parseExpr()
		if err != nil {
			return 0, err
		}
		p.skipSpace()
		if p.peek() != ')' {
			return 0, fmt.Errorf("expected closing parenthesis")
		}
		p.pos++
		return val, nil
	}

	start := p.pos
	for p.pos < len(p.input) && (p.input[p.pos] >= '0' && p.input[p.pos] <= '9' || p.input[p.pos] == '.') {
		p.pos++
	}
	if p.pos == start {
		return 0, fmt.Errorf("expected a number at position %d", p.pos)
	}
	numStr := string(p.input[start:p.pos])
	if strings.Count(numStr, ".") > 1 {
		return 0, fmt.Errorf("invalid number literal")
	}
	val, err := strconv.ParseFloat(numStr, 64)
	if err != nil {
		return 0, err
	}
	return val, nil
}

// formatMathResult formats a float the way Python's str() would. Python 3's
// eval() keeps a whole-number result as an int (str(8) == "8") unless the
// expression used true division ('/') or contained a literal decimal point,
// in which case it's a float (str(8.0) == "8.0"). forceFloat should be true
// whenever the original input contained '/' or '.'.
func formatMathResult(v float64, forceFloat bool) string {
	if v == math.Trunc(v) && !math.IsInf(v, 0) {
		if forceFloat {
			return strconv.FormatFloat(v, 'f', 1, 64)
		}
		return strconv.FormatFloat(v, 'f', 0, 64)
	}
	return strconv.FormatFloat(v, 'g', -1, 64)
}
